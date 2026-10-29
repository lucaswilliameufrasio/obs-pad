import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'protocol.dart';

enum CompanionErrorKind {
  /// Nobody answered: app not open on the computer, or a firewall.
  unreachable,

  /// Signature refused: the OBS password on the phone is different.
  unauthorized,

  /// The phone and computer clocks differ by more than a few minutes.
  clockSkew,

  /// The OBS WebSocket server on the computer has no password yet.
  notReady,
  tooLarge,

  /// Not a sound file OBS can play.
  badFile,
  server,
}

class CompanionException implements Exception {
  const CompanionException(this.kind, [this.detail]);

  final CompanionErrorKind kind;
  final String? detail;

  @override
  String toString() => 'CompanionException($kind, $detail)';
}

/// Talks to OBS Pad Desktop on the OBS computer.
class CompanionClient {
  CompanionClient({
    required this.host,
    required this.secret,
    this.port = defaultCompanionPort,
    this.timeout = const Duration(seconds: 5),
    this.uploadTimeout = const Duration(minutes: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String host;
  final int port;

  /// The OBS WebSocket password.
  final String secret;
  final Duration timeout;
  final Duration uploadTimeout;
  final DateTime Function() _clock;

  final HttpClient _http = HttpClient();

  void close() => _http.close(force: true);

  /// Unsigned: is the app there, and is it ready?
  Future<({CompanionAnnouncement info, bool ready})> info() async {
    final json = await _send('GET', '/info', signed: false);
    return (
      info: CompanionAnnouncement.fromJson(json),
      ready: json['ready'] as bool? ?? false,
    );
  }

  Future<({String folder, List<SoundFile> sounds})> listSounds() async {
    final json = await _send('GET', '/sounds');
    final sounds = json['sounds'];
    return (
      folder: json['folder'] as String? ?? '',
      sounds: [
        if (sounds is List)
          for (final s in sounds)
            if (s is Map<String, Object?>) SoundFile.fromJson(s),
      ],
    );
  }

  /// Copies a sound to the computer's sounds folder and returns where it
  /// is, ready to be used in an OBS Media Source.
  Future<SoundFile> uploadSound(String fileName, List<int> bytes) async {
    if (safeSoundFileName(fileName) == null) {
      throw CompanionException(CompanionErrorKind.badFile, fileName);
    }
    if (bytes.length > maxSoundBytes) {
      throw const CompanionException(CompanionErrorKind.tooLarge);
    }
    final json = await _send(
      'POST',
      '/sounds',
      body: bytes,
      headers: {fileNameHeader: Uri.encodeComponent(fileName)},
      timeout: uploadTimeout,
    );
    return SoundFile.fromJson(json);
  }

  Future<Map<String, Object?>> _send(
    String method,
    String endpoint, {
    bool signed = true,
    List<int> body = const [],
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    final path = '$apiPrefix$endpoint';
    final uri = Uri(scheme: 'http', host: host, port: port, path: path);
    try {
      return await () async {
        final request = await _http.openUrl(method, uri);
        headers.forEach(request.headers.set);
        if (signed) {
          final time = _clock().millisecondsSinceEpoch ~/ 1000;
          request.headers
            ..set(timeHeader, '$time')
            ..set(
              signatureHeader,
              signRequest(
                secret: secret,
                method: method,
                path: path,
                timestampSeconds: time,
                body: body,
              ),
            );
        }
        request.contentLength = body.length;
        if (body.isNotEmpty) request.add(body);
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        final json = _decode(text);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return json;
        }
        throw _errorFor(response.statusCode, json['error'] as String?);
      }().timeout(timeout ?? this.timeout);
    } on CompanionException {
      rethrow;
    } on TimeoutException {
      throw const CompanionException(CompanionErrorKind.unreachable, 'timeout');
    } on SocketException catch (error) {
      throw CompanionException(CompanionErrorKind.unreachable, error.message);
    } on HttpException catch (error) {
      throw CompanionException(CompanionErrorKind.unreachable, error.message);
    }
  }

  static Map<String, Object?> _decode(String text) {
    try {
      final json = jsonDecode(text);
      return json is Map<String, Object?> ? json : {};
    } on FormatException {
      return {};
    }
  }

  static CompanionException _errorFor(int status, String? code) =>
      switch (code) {
        'unauthorized' => const CompanionException(
          CompanionErrorKind.unauthorized,
        ),
        'clock_skew' => const CompanionException(CompanionErrorKind.clockSkew),
        'not_ready' => const CompanionException(CompanionErrorKind.notReady),
        'too_large' => const CompanionException(CompanionErrorKind.tooLarge),
        'bad_file' => const CompanionException(CompanionErrorKind.badFile),
        _ => CompanionException(CompanionErrorKind.server, '$status $code'),
      };
}

/// A computer that answered discovery.
class DiscoveredComputer {
  const DiscoveredComputer(this.address, this.announcement);

  final String address;
  final CompanionAnnouncement announcement;
}

/// Finds computers running OBS Pad Desktop on the local network.
///
/// Sends a UDP broadcast and collects answers for [timeout]. [extraTargets]
/// are also asked directly (e.g. a known IP, or loopback in tests).
Future<List<DiscoveredComputer>> discoverComputers({
  Duration timeout = const Duration(seconds: 2),
  int port = defaultCompanionPort,
  bool broadcast = true,
  List<InternetAddress> extraTargets = const [],
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
    ..broadcastEnabled = true;
  final found = <String, DiscoveredComputer>{};
  final subscription = socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram == null) return;
    final announcement = CompanionAnnouncement.tryParse(datagram.data);
    if (announcement == null) return;
    final address = datagram.address.address;
    found[address] = DiscoveredComputer(address, announcement);
  });

  final message = utf8.encode(discoveryRequest);
  final targets = [
    if (broadcast) InternetAddress('255.255.255.255'),
    ...extraTargets,
  ];
  // A couple of tries: UDP may drop one on busy Wi-Fi.
  for (var attempt = 0; attempt < 3; attempt++) {
    for (final target in targets) {
      try {
        socket.send(message, target, port);
      } on SocketException {
        // Broadcast not allowed on this network/OS: rely on the others.
      }
    }
    await Future<void>.delayed(timeout ~/ 3);
  }
  await subscription.cancel();
  socket.close();
  return found.values.toList();
}
