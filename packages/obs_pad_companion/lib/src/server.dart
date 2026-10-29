import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'protocol.dart';

enum CompanionActivityKind { discovered, listed, uploaded, rejected }

/// Something the phone did, shown in the desktop app.
class CompanionActivity {
  CompanionActivity(this.kind, this.remote, [this.detail = ''])
    : time = DateTime.now();

  final CompanionActivityKind kind;
  final String remote;

  /// File name for uploads, reason for rejections.
  final String detail;
  final DateTime time;
}

/// Runs on the OBS computer: answers discovery and receives sound files.
class CompanionServer {
  CompanionServer({
    required this.secret,
    required this.soundsDir,
    required this.announcement,
    this.port = defaultCompanionPort,
    this.maxUploadBytes = maxSoundBytes,
    this.onActivity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The OBS WebSocket password, read on every request (the user may change
  /// it in OBS). Null or empty: signed requests are refused.
  final String? Function() secret;
  final Directory soundsDir;

  /// What discovery answers; read on every request too.
  final CompanionAnnouncement Function() announcement;

  /// 0 picks a free port (tests).
  final int port;
  final int maxUploadBytes;
  final void Function(CompanionActivity activity)? onActivity;
  final DateTime Function() _clock;

  HttpServer? _http;
  RawDatagramSocket? _udp;

  int get httpPort => _http?.port ?? port;
  int get discoveryPort => _udp?.port ?? port;

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _http!.listen((request) => unawaited(_handle(request)));
    _udp = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port == 0 ? 0 : port,
    );
    _udp!.listen(_onDatagram);
  }

  Future<void> stop() async {
    _udp?.close();
    _udp = null;
    await _http?.close(force: true);
    _http = null;
  }

  void _onDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final udp = _udp;
    final datagram = udp?.receive();
    if (udp == null || datagram == null) return;
    if (utf8.decode(datagram.data, allowMalformed: true) != discoveryRequest) {
      return;
    }
    final reply = utf8.encode(jsonEncode(announcement().toJson()));
    udp.send(reply, datagram.address, datagram.port);
    _report(CompanionActivityKind.discovered, datagram.address.address);
  }

  void _report(
    CompanionActivityKind kind,
    String remote, [
    String detail = '',
  ]) => onActivity?.call(CompanionActivity(kind, remote, detail));

  Future<void> _handle(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress.address ?? '?';
    final response = request.response;
    try {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '$apiPrefix/info') {
        final info = announcement();
        await _json(response, 200, {
          ...info.toJson(),
          'ready': (secret() ?? '').isNotEmpty,
        });
        return;
      }
      if (path != '$apiPrefix/sounds' ||
          (request.method != 'GET' && request.method != 'POST')) {
        await _error(response, 404, 'not_found');
        return;
      }

      final body = await _readBody(request);
      if (body == null) {
        _report(CompanionActivityKind.rejected, remote, 'too_large');
        await _error(response, 413, 'too_large');
        return;
      }
      final denied = _checkSignature(request, body);
      if (denied != null) {
        _report(CompanionActivityKind.rejected, remote, denied.$2);
        await _error(response, denied.$1, denied.$2);
        return;
      }

      if (request.method == 'GET') {
        final sounds = await listSounds();
        _report(CompanionActivityKind.listed, remote);
        await _json(response, 200, {
          'folder': soundsDir.path,
          'sounds': [for (final s in sounds) s.toJson()],
        });
        return;
      }

      final rawName = Uri.decodeComponent(
        request.headers.value(fileNameHeader) ?? '',
      );
      final name = safeSoundFileName(rawName);
      if (name == null || body.isEmpty) {
        _report(CompanionActivityKind.rejected, remote, 'bad_file $rawName');
        await _error(response, 400, 'bad_file');
        return;
      }
      final saved = await _save(name, body);
      _report(CompanionActivityKind.uploaded, remote, saved.name);
      await _json(response, 201, saved.toJson());
    } on Object catch (error) {
      await _error(response, 500, 'server', '$error');
    }
  }

  /// Null when the body is bigger than [maxUploadBytes].
  Future<List<int>?> _readBody(HttpRequest request) async {
    final declared = request.contentLength;
    if (declared > maxUploadBytes) return null;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      builder.add(chunk);
      if (builder.length > maxUploadBytes) return null;
    }
    return builder.takeBytes();
  }

  /// (status, error code) when the request is not signed correctly.
  (int, String)? _checkSignature(HttpRequest request, List<int> body) {
    final key = secret() ?? '';
    if (key.isEmpty) return (503, 'not_ready');
    final time = int.tryParse(request.headers.value(timeHeader) ?? '');
    final signature = request.headers.value(signatureHeader) ?? '';
    if (time == null || signature.isEmpty) return (401, 'unauthorized');
    final now = _clock().millisecondsSinceEpoch ~/ 1000;
    if ((now - time).abs() > maxClockSkew.inSeconds) {
      return (401, 'clock_skew');
    }
    final expected = signRequest(
      secret: key,
      method: request.method,
      path: request.uri.path,
      timestampSeconds: time,
      body: body,
    );
    if (!signaturesMatch(signature, expected)) return (401, 'unauthorized');
    return null;
  }

  /// Sound files in the folder, newest first.
  Future<List<SoundFile>> listSounds() async {
    if (!soundsDir.existsSync()) return [];
    final files = <(File, FileStat)>[];
    await for (final entity in soundsDir.list()) {
      if (entity is! File) continue;
      if (!soundExtensions.contains(p.extension(entity.path).toLowerCase())) {
        continue;
      }
      files.add((entity, await entity.stat()));
    }
    files.sort((a, b) => b.$2.modified.compareTo(a.$2.modified));
    return [
      for (final (file, stat) in files)
        SoundFile(
          name: p.basename(file.path),
          path: file.absolute.path,
          sizeBytes: stat.size,
        ),
    ];
  }

  /// Saves without overwriting a different file with the same name: the
  /// same content returns the existing file, other content gets " (2)".
  Future<SoundFile> _save(String name, List<int> bytes) async {
    await soundsDir.create(recursive: true);
    final stem = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    for (var n = 1; ; n++) {
      final candidate = n == 1 ? name : '$stem ($n)$ext';
      final file = File(p.join(soundsDir.path, candidate));
      if (file.existsSync()) {
        if (await _sameContent(file, bytes)) return _describe(file);
        continue;
      }
      await file.writeAsBytes(bytes, flush: true);
      return _describe(file);
    }
  }

  static Future<bool> _sameContent(File file, List<int> bytes) async {
    if (await file.length() != bytes.length) return false;
    final existing = await file.readAsBytes();
    for (var i = 0; i < bytes.length; i++) {
      if (existing[i] != bytes[i]) return false;
    }
    return true;
  }

  static SoundFile _describe(File file) => SoundFile(
    name: p.basename(file.path),
    path: file.absolute.path,
    sizeBytes: file.lengthSync(),
  );

  static Future<void> _json(
    HttpResponse response,
    int status,
    Map<String, Object?> body,
  ) async {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await response.close();
  }

  static Future<void> _error(
    HttpResponse response,
    int status,
    String code, [
    String message = '',
  ]) => _json(response, status, {
    'error': code,
    if (message.isNotEmpty) 'message': message,
  });
}
