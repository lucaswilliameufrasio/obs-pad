import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/data/obs/websocket_obs_repository.dart';
import 'package:obs_pad/domain/obs_events.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_pad/domain/obs_models.dart';
import 'package:obs_websocket/obs_websocket.dart' show ObsUtil;

/// Minimal obs-websocket 5.x server: Hello/Identify with auth, requests and
/// events. Enough to exercise the real repository end to end.
class FakeObsServer {
  FakeObsServer({this.password = 'segredo'});

  final String password;
  late final HttpServer _server;
  final sockets = <WebSocket>[];
  final requests = <Map<String, Object?>>[];
  int lastEventMask = 0;
  String currentScene = 'Cena A';

  int get port => _server.port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      _send(socket, {
        'op': 0,
        'd': {
          'obsWebSocketVersion': '5.5.0',
          'rpcVersion': 1,
          'authentication': {'challenge': 'chal', 'salt': 'salt'},
        },
      });
      socket.listen((raw) => _onMessage(socket, raw as String));
    });
  }

  void _onMessage(WebSocket socket, String raw) {
    if (socket.closeCode != null) return;
    final msg = jsonDecode(raw) as Map<String, Object?>;
    final d = msg['d']! as Map<String, Object?>;
    switch (msg['op']) {
      case 1: // Identify
        final secret = ObsUtil.base64Hash('${password}salt');
        final expected = ObsUtil.base64Hash('${secret}chal');
        if (d['authentication'] != expected) {
          unawaited(socket.close(4009, 'Authentication failed.'));
          return;
        }
        lastEventMask = (d['eventSubscriptions'] as int?) ?? 0;
        _send(socket, {
          'op': 2,
          'd': {'negotiatedRpcVersion': 1},
        });
      case 3: // Reidentify
        lastEventMask = (d['eventSubscriptions'] as int?) ?? 0;
        _send(socket, {
          'op': 2,
          'd': {'negotiatedRpcVersion': 1},
        });
      case 6: // Request
        requests.add(d);
        _send(socket, {'op': 7, 'd': _respond(d)});
    }
  }

  Map<String, Object?> _respond(Map<String, Object?> d) {
    final type = d['requestType']! as String;
    final data = (d['requestData'] as Map<String, Object?>?) ?? const {};
    Map<String, Object?> ok([Map<String, Object?>? responseData]) => {
      'requestType': type,
      'requestId': d['requestId'],
      'requestStatus': {'result': true, 'code': 100},
      'responseData': ?responseData,
    };
    Map<String, Object?> fail(int code, String comment) => {
      'requestType': type,
      'requestId': d['requestId'],
      'requestStatus': {'result': false, 'code': code, 'comment': comment},
    };
    switch (type) {
      case 'GetVersion':
        return ok({
          'obsVersion': '31.0.2',
          'obsWebSocketVersion': '5.5.0',
          'rpcVersion': 1,
        });
      case 'GetSceneList':
        return ok({
          'currentProgramSceneName': currentScene,
          'scenes': [
            {'sceneIndex': 0, 'sceneName': 'Cena B'},
            {'sceneIndex': 1, 'sceneName': 'Cena A'},
          ],
        });
      case 'SetCurrentProgramScene':
        final name = data['sceneName'];
        if (name != 'Cena A' && name != 'Cena B') {
          return fail(600, 'No source was found by the name of `$name`.');
        }
        currentScene = name! as String;
        broadcast('CurrentProgramSceneChanged', {'sceneName': name});
        return ok();
      default:
        return ok();
    }
  }

  /// Clients may be closing while we answer; ignore writes to dead sockets.
  void _send(WebSocket socket, Map<String, Object?> message) {
    try {
      socket.add(jsonEncode(message));
    } on StateError {
      // socket already closed
    }
  }

  void broadcast(String eventType, Map<String, Object?> data) {
    for (final socket in sockets.where((s) => s.closeCode == null)) {
      _send(socket, {
        'op': 5,
        'd': {'eventType': eventType, 'eventIntent': 4, 'eventData': data},
      });
    }
  }

  Future<void> dropClients() async {
    for (final socket in sockets) {
      await socket.close(1001);
    }
    sockets.clear();
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late FakeObsServer server;
  late WebSocketObsRepository repo;

  setUp(() async {
    server = FakeObsServer();
    await server.start();
    repo = WebSocketObsRepository(
      requestTimeout: const Duration(seconds: 2),
      maxBackoff: const Duration(seconds: 1),
    );
  });

  tearDown(() async {
    await repo.dispose();
    await server.stop();
  });

  ObsConnectionConfig config({String password = 'segredo', int? port}) =>
      ObsConnectionConfig(
        host: '127.0.0.1',
        port: port ?? server.port,
        password: password,
        timeout: const Duration(seconds: 2),
      );

  test('testConnection returns the OBS version', () async {
    final info = await repo.testConnection(config());
    expect(info.obsVersion, '31.0.2');
    expect(info.obsMajorVersion, 31);
  });

  test('wrong password is detected from close code 4009', () async {
    await expectLater(
      repo.testConnection(config(password: 'errada')),
      throwsA(
        isA<ObsFailure>().having(
          (f) => f.kind,
          'kind',
          ObsFailureKind.wrongPassword,
        ),
      ),
    );
  });

  test('closed port is reported as server off', () async {
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    await expectLater(
      repo.testConnection(config(port: port)),
      throwsA(
        isA<ObsFailure>().having(
          (f) => f.kind,
          'kind',
          ObsFailureKind.serverOff,
        ),
      ),
    );
  });

  test('connect subscribes to events and switches scenes', () async {
    await repo.connect(config());
    expect(repo.status, isA<ObsConnected>());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.lastEventMask, 4095);

    final scenes = await repo.getScenes();
    expect(scenes.map((s) => s.name), ['Cena A', 'Cena B']);

    final changed = repo.events.firstWhere((e) => e is CurrentSceneChanged);
    await repo.setCurrentProgramScene('Cena B');
    final event = await changed.timeout(const Duration(seconds: 2));
    expect((event as CurrentSceneChanged).sceneName, 'Cena B');
  });

  test(
    'unknown scene becomes a resourceNotFound failure with its name',
    () async {
      await repo.connect(config());
      await expectLater(
        repo.setCurrentProgramScene('Não existe'),
        throwsA(
          isA<ObsFailure>()
              .having((f) => f.kind, 'kind', ObsFailureKind.resourceNotFound)
              .having((f) => f.resource, 'resource', 'Não existe'),
        ),
      );
    },
  );

  test('volume meters subscription is toggled on demand', () async {
    await repo.connect(config());
    await repo.setVolumeMetersEnabled(enabled: true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.lastEventMask, 4095 | 65536);
    await repo.setVolumeMetersEnabled(enabled: false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.lastEventMask, 4095);
  });

  test('reconnects with backoff after the connection drops', () async {
    await repo.connect(config());
    final statuses = <ObsConnectionStatus>[];
    final sub = repo.statusChanges.listen(statuses.add);

    await server.dropClients();
    final reconnected = repo.statusChanges.firstWhere((s) => s is ObsConnected);
    await reconnected.timeout(const Duration(seconds: 5));
    await sub.cancel();

    expect(statuses.whereType<ObsReconnecting>(), isNotEmpty);
    expect(repo.status, isA<ObsConnected>());
  });

  test('wrong password does not retry forever', () async {
    await expectLater(
      repo.connect(config(password: 'errada')),
      throwsA(isA<ObsFailure>()),
    );
    expect(repo.status, isA<ObsConnectionFailed>());
  });
}
