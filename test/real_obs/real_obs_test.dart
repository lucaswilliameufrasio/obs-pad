/// End-to-end tests against a real OBS Studio (see tool/obs-docker).
///
/// Skipped unless OBS_PAD_REAL_OBS is set:
///
///     tool/obs-docker/run-tests.sh
///
/// or, with the container already running:
///
///     OBS_PAD_REAL_OBS=1 flutter test test/real_obs
@Tags(['real-obs'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/data/obs/websocket_obs_repository.dart';
import 'package:obs_pad/domain/audio_math.dart';
import 'package:obs_pad/domain/metrics/metrics_calculator.dart';
import 'package:obs_pad/domain/obs_events.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_pad/domain/obs_models.dart';
import 'package:obs_pad/domain/sound/ducking_controller.dart';
import 'package:obs_websocket/obs_websocket.dart' as raw;

final _env = Platform.environment;
final _enabled = _env.containsKey('OBS_PAD_REAL_OBS');
final _host = _env['OBS_HOST'] ?? '127.0.0.1';
final _port = int.parse(_env['OBS_PORT'] ?? '4455');
final _password = _env['OBS_PASSWORD'] ?? 'obspad-test';

/// Container restarted by the reconnect test; empty = skip that test.
final _container = _env['OBS_PAD_DOCKER_CONTAINER'] ?? '';

const _soundFile = '/home/obs/sounds/beep.wav';

ObsConnectionConfig _config({String? password, int? port}) =>
    ObsConnectionConfig(
      host: _host,
      port: port ?? _port,
      password: password ?? _password,
    );

/// Sets up scenes and sources with the plain obs_websocket client, so the
/// repository under test only does what the app does.
Future<void> _prepareObs() async {
  final obs = await raw.ObsWebSocket.connect(
    'ws://$_host:$_port',
    password: _password,
    timeout: const Duration(seconds: 10),
  );
  Future<void> send(String type, Map<String, Object?> data) async {
    try {
      await obs.sendRequest(
        raw.Request(type, requestData: data, expectResponse: true),
      );
    } on raw.ObsRequestException {
      // Already exists from a previous run.
    }
  }

  for (final scene in ['Começando', 'Jogo', 'Intervalo']) {
    await send('CreateScene', {'sceneName': scene});
  }
  await send('CreateInput', {
    'sceneName': 'Jogo',
    'inputName': 'Placa',
    'inputKind': 'color_source_v3',
    'inputSettings': {'color': 0xFF3355FF},
    'sceneItemEnabled': true,
  });
  await send('SetCurrentProgramScene', {'sceneName': 'Começando'});
  await _useProfile(obs, 'Padrao');
  // The live goes to the local RTMP sink of the container.
  await send('SetStreamServiceSettings', {
    'streamServiceType': 'rtmp_custom',
    'streamServiceSettings': {
      'server': 'rtmp://127.0.0.1:1935/live',
      'key': 'test',
    },
  });
  await obs.close();
}

/// OBS profiles baked into the image (tool/obs-docker/config): "Padrao" has
/// the OBS defaults, "Gravacao" records with its own encoder.
Future<void> _useProfile(raw.ObsWebSocket obs, String profile) async {
  try {
    await obs.sendRequest(
      raw.Request(
        'SetCurrentProfile',
        requestData: {'profileName': profile},
        expectResponse: true,
      ),
    );
  } on raw.ObsRequestException {
    // Already the current profile.
  }
}

Future<void> _withRawObs(Future<void> Function(raw.ObsWebSocket) body) async {
  final obs = await raw.ObsWebSocket.connect(
    'ws://$_host:$_port',
    password: _password,
    timeout: const Duration(seconds: 10),
  );
  try {
    await body(obs);
  } finally {
    await obs.close();
  }
}

Future<T> _next<T extends ObsEvent>(
  WebSocketObsRepository repo, {
  bool Function(T event)? where,
  Duration timeout = const Duration(seconds: 15),
}) => repo.events
    .where((e) => e is T && (where?.call(e) ?? true))
    .cast<T>()
    .first
    .timeout(timeout);

Future<void> _until(
  Future<bool> Function() check, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met', timeout);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

void main() {
  if (!_enabled) {
    test(
      'real OBS tests',
      () {},
      skip: 'set OBS_PAD_REAL_OBS=1 (see tool/obs-docker)',
    );
    return;
  }

  setUpAll(_prepareObs);

  group('connection test (onboarding step 4)', () {
    test('right password: reports the OBS and websocket versions', () async {
      final info = await WebSocketObsRepository().testConnection(_config());
      expect(info.obsVersion, isNotEmpty);
      expect(info.webSocketVersion, startsWith('5.'));
    });

    test('wrong password is reported as such', () async {
      await expectLater(
        WebSocketObsRepository().testConnection(_config(password: 'errada')),
        throwsA(
          isA<ObsFailure>().having(
            (f) => f.kind,
            'kind',
            ObsFailureKind.wrongPassword,
          ),
        ),
      );
    });

    test('wrong port means "server off"', () async {
      await expectLater(
        WebSocketObsRepository().testConnection(_config(port: 4456)),
        throwsA(
          isA<ObsFailure>().having(
            (f) => f.kind,
            'kind',
            ObsFailureKind.serverOff,
          ),
        ),
      );
    });
  });

  group('connected', () {
    late WebSocketObsRepository repo;

    setUp(() async {
      repo = WebSocketObsRepository();
      await repo.connect(_config());
    });

    tearDown(() => repo.disconnect());

    test('scenes: list, switch and follow the change event', () async {
      final names = (await repo.getScenes()).map((s) => s.name);
      expect(names, containsAll(['Começando', 'Jogo', 'Intervalo']));

      final changed = _next<CurrentSceneChanged>(
        repo,
        where: (e) => e.sceneName == 'Jogo',
      );
      await repo.setCurrentProgramScene('Jogo');
      await changed;
      expect(await repo.getCurrentProgramScene(), 'Jogo');
    });

    test('missing scene gives resourceNotFound with its name', () async {
      await expectLater(
        repo.setCurrentProgramScene('Não existe'),
        throwsA(
          isA<ObsFailure>()
              .having((f) => f.kind, 'kind', ObsFailureKind.resourceNotFound)
              .having((f) => f.resource, 'resource', 'Não existe'),
        ),
      );
    });

    test('toggle a source in a scene', () async {
      final item = (await repo.getSceneItems('Jogo'))
          .firstWhere((i) => i.sourceName == 'Placa');
      final changed = _next<SceneItemEnabledChanged>(repo);
      await repo.setSceneItemEnabled('Jogo', item.id, enabled: !item.enabled);
      expect((await changed).enabled, !item.enabled);
      await repo.setSceneItemEnabled('Jogo', item.id, enabled: item.enabled);
    });

    test('add sound: creates the media source in every scene', () async {
      await repo.setupMediaSource(
        const MediaSourceRequest(
          inputName: 'Som - Beep',
          filePath: _soundFile,
          sceneName: 'Jogo',
          alsoAddToScenes: ['Começando', 'Intervalo'],
        ),
      );
      for (final scene in ['Começando', 'Jogo', 'Intervalo']) {
        final items = await repo.getSceneItems(scene);
        expect(
          items.map((i) => i.sourceName),
          contains('Som - Beep'),
          reason: scene,
        );
      }
      expect(
        (await repo.getInputs()).firstWhere((i) => i.name == 'Som - Beep'),
        isA<ObsInput>().having((i) => i.isMediaSource, 'media', isTrue),
      );
      // Running it again updates instead of failing.
      expect(
        await repo.setupMediaSource(
          const MediaSourceRequest(
            inputName: 'Som - Beep',
            filePath: _soundFile,
            sceneName: 'Jogo',
          ),
        ),
        MediaSourceSetupResult.updated,
      );
    });

    test('sound pad: plays, meters move, and the end event arrives', () async {
      await repo.setupMediaSource(
        const MediaSourceRequest(
          inputName: 'Som - Beep',
          filePath: _soundFile,
          sceneName: 'Jogo',
          alsoAddToScenes: ['Começando', 'Intervalo'],
        ),
      );
      await repo.setVolumeMetersEnabled(enabled: true);
      final peaks = <double>[];
      final sub = repo.events.listen((e) {
        if (e is InputVolumeMeters) peaks.add(e.peaks['Som - Beep'] ?? 0);
      });

      final started = _next<MediaPlaybackStarted>(
        repo,
        where: (e) => e.inputName == 'Som - Beep',
      );
      final ended = _next<MediaPlaybackEnded>(
        repo,
        where: (e) => e.inputName == 'Som - Beep',
      );
      await repo.triggerMediaAction('Som - Beep', ObsMediaAction.restart);
      await started;
      expect(await repo.getMediaState('Som - Beep'), ObsMediaState.playing);
      await ended;
      await sub.cancel();
      await repo.setVolumeMetersEnabled(enabled: false);

      expect(peaks, isNotEmpty, reason: 'InputVolumeMeters never arrived');
      expect(peaks.reduce((a, b) => a > b ? a : b), greaterThan(0.01));
    });

    test('missing media input gives resourceNotFound', () async {
      await expectLater(
        repo.triggerMediaAction('Som que sumiu', ObsMediaAction.restart),
        throwsA(
          isA<ObsFailure>().having(
            (f) => f.kind,
            'kind',
            ObsFailureKind.resourceNotFound,
          ),
        ),
      );
    });

    test('mixer: mute and volume, with events', () async {
      final muted = _next<InputMuteChanged>(
        repo,
        where: (e) => e.inputName == 'Som - Beep',
      );
      await repo.setInputMute('Som - Beep', muted: true);
      expect((await muted).muted, isTrue);
      await repo.setInputMute('Som - Beep', muted: false);

      await repo.setInputVolume('Som - Beep', 0.25);
      expect(await repo.getInputVolume('Som - Beep'), closeTo(0.25, 0.001));
      final audio = await repo.getAudioInputs();
      expect(audio.map((a) => a.name), contains('Som - Beep'));
      await repo.setInputVolume('Som - Beep', 1);
    });

    test('ducking lowers and restores a real input', () async {
      final ducking = DuckingController(
        readVolume: repo.getInputVolume,
        writeVolume: repo.setInputVolume,
      );
      await repo.setInputVolume('Som - Beep', 0.5);
      await ducking.duck(sound: 'x', target: 'Som - Beep', reductionDb: 20);
      expect(await repo.getInputVolume('Som - Beep'), closeTo(0.05, 0.001));
      await ducking.release('x');
      expect(await repo.getInputVolume('Som - Beep'), closeTo(0.5, 0.001));
      expect(mulToDb(await repo.getInputVolume('Som - Beep')), lessThan(0));
      await repo.setInputVolume('Som - Beep', 1);
    });

    Future<RecordStateChanged> nextRecord(String state) =>
        _next<RecordStateChanged>(repo, where: (e) => e.state == state);

    Future<void> startRecording() async {
      final started = nextRecord('OBS_WEBSOCKET_OUTPUT_STARTED');
      await repo.startRecord();
      await started;
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    Future<void> stopRecording() async {
      final stopped = nextRecord('OBS_WEBSOCKET_OUTPUT_STOPPED');
      await repo.stopRecord();
      await stopped;
    }

    test('record with OBS defaults: pause is refused with a reason', () async {
      // Default "Recording quality: same as stream": OBS answers the pause
      // request with success but keeps recording.
      await startRecording();
      try {
        await expectLater(
          repo.toggleRecordPause(),
          throwsA(
            isA<ObsFailure>().having(
              (f) => f.kind,
              'kind',
              ObsFailureKind.recordPauseUnsupported,
            ),
          ),
        );
        expect((await repo.getRecordStatus()).paused, isFalse);
      } finally {
        await stopRecording();
      }
    });

    test('record: start, pause, resume and stop with events', () async {
      await _withRawObs((obs) => _useProfile(obs, 'Gravacao'));
      addTearDown(() => _withRawObs((obs) => _useProfile(obs, 'Padrao')));

      await startRecording();
      expect((await repo.getRecordStatus()).active, isTrue);
      // The first bytes are reported after the muxer flushes.
      await _until(() async => (await repo.getRecordStatus()).bytes > 0);

      final paused = nextRecord('OBS_WEBSOCKET_OUTPUT_PAUSED');
      await repo.toggleRecordPause();
      // OBS sends outputActive: false here; the app must still show it as
      // recording (paused).
      expect((await paused).active, isTrue);
      expect((await repo.getRecordStatus()).paused, isTrue);

      final resumed = nextRecord('OBS_WEBSOCKET_OUTPUT_RESUMED');
      await repo.toggleRecordPause();
      await resumed;
      await stopRecording();

      // Stopping twice is a human error, not a crash.
      await expectLater(
        repo.stopRecord(),
        throwsA(
          isA<ObsFailure>().having(
            (f) => f.kind,
            'kind',
            ObsFailureKind.outputNotActive,
          ),
        ),
      );
    });

    test('live: dashboard metrics from a real stream', () async {
      final calc = MetricsCalculator();
      Future<void> sample() async {
        final (stats, stream, record) = await (
          repo.getStats(),
          repo.getStreamStatus(),
          repo.getRecordStatus(),
        ).wait;
        calc.add(
          MetricsSample(
            time: DateTime.now(),
            stats: stats,
            stream: stream,
            record: record,
          ),
        );
      }

      final started = _next<StreamStateChanged>(
        repo,
        where: (e) => e.active,
        timeout: const Duration(seconds: 30),
      );
      await repo.startStream();
      await started;
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        await sample();
      }
      final stopped = _next<StreamStateChanged>(repo, where: (e) => !e.active);
      await repo.stopStream();
      await stopped;

      final point = calc.latest!;
      expect(point.sample.stream.active, isTrue);
      expect(point.bitrateSource, BitrateSource.stream);
      // Default simple-output bitrate is 2500 kbps; a static scene sends
      // less, but never zero.
      expect(point.bitrateKbps, isNotNull);
      expect(point.bitrateKbps, greaterThan(10));
      expect(point.bitrateKbps, lessThan(20000));
      expect(point.sample.stats.activeFps, greaterThan(0));
      expect(point.recentDropPct, lessThan(1));
    });

    test('replay buffer off: saving gives a human error', () async {
      expect(await repo.getReplayBufferActive(), isFalse);
      await expectLater(
        repo.saveReplayBuffer(),
        throwsA(
          isA<ObsFailure>().having(
            (f) => f.kind,
            'kind',
            ObsFailureKind.replayBufferOff,
          ),
        ),
      );
    });

    test('hotkeys: list and trigger by name', () async {
      final hotkeys = await repo.getHotkeys();
      expect(hotkeys, contains('OBSBasic.StartRecording'));
      await repo.triggerHotkey('OBSBasic.Screenshot');
    });
  });

  test('reconnects by itself when OBS restarts', () async {
    final repo = WebSocketObsRepository();
    await repo.connect(_config());
    final statuses = <ObsConnectionStatus>[];
    final sub = repo.statusChanges.listen(statuses.add);

    final result = await Process.run('docker', ['restart', _container]);
    expect(result.exitCode, 0, reason: '${result.stderr}');

    await _until(
      () async => repo.status is ObsConnected,
      timeout: const Duration(seconds: 60),
    );
    await sub.cancel();
    expect(statuses.whereType<ObsReconnecting>(), isNotEmpty);
    // Events work again after reconnecting.
    await _prepareObs();
    final changed = _next<CurrentSceneChanged>(repo);
    await repo.setCurrentProgramScene('Intervalo');
    expect((await changed).sceneName, 'Intervalo');
    await repo.disconnect();
  }, skip: _container.isEmpty ? 'set OBS_PAD_DOCKER_CONTAINER' : false);
}
