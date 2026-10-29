import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:obs_websocket/obs_websocket.dart' hide ObsMediaState;
import 'package:web_socket_channel/io.dart';

import '../../core/json.dart';
import '../../domain/obs_events.dart';
import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../../domain/obs_repository.dart';
import 'obs_error_mapper.dart';

/// Event subscription bits of the obs-websocket 5.x protocol.
const int _allEvents = 4095; // EventSubscription.All (low-volume)
const int _volumeMetersEvent = 65536; // EventSubscription.InputVolumeMeters

/// [ObsRepository] backed by the obs_websocket package (protocol v5).
///
/// Every request goes through [_call], which uses the raw request API so
/// failures of "Set*" requests are reported too (the package only checks
/// "Get*" responses by default).
class WebSocketObsRepository implements ObsRepository {
  WebSocketObsRepository({
    this.requestTimeout = const Duration(seconds: 8),
    this.maxBackoff = const Duration(seconds: 30),
  });

  final Duration requestTimeout;
  final Duration maxBackoff;

  final _statusController = StreamController<ObsConnectionStatus>.broadcast();
  final _eventsController = StreamController<ObsEvent>.broadcast();

  ObsConnectionStatus _status = const ObsDisconnected();
  _Session? _session;
  ObsConnectionConfig? _config;
  bool _wantConnected = false;
  bool _metersEnabled = false;
  int _attempt = 0;
  int _generation = 0;
  Timer? _retryTimer;

  @override
  ObsConnectionStatus get status => _status;

  @override
  Stream<ObsConnectionStatus> get statusChanges => _statusController.stream;

  @override
  Stream<ObsEvent> get events => _eventsController.stream;

  void _setStatus(ObsConnectionStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  Future<_Session> _open(ObsConnectionConfig config) async {
    final WebSocket socket;
    try {
      socket = await WebSocket.connect(config.uri.toString())
          .timeout(config.timeout);
    } catch (error) {
      throw mapObsError(error);
    }

    final channel = IOWebSocketChannel(socket);
    final obs = ObsWebSocket(
      channel,
      password: config.password.isEmpty ? null : config.password,
    );
    try {
      await obs.init().timeout(config.timeout);
      final version = await _send(obs, 'GetVersion');
      return _Session(
        obs: obs,
        socket: socket,
        info: ObsServerInfo(
          obsVersion: version.str('obsVersion'),
          webSocketVersion: version.str('obsWebSocketVersion'),
          rpcVersion: version.integer('rpcVersion', 1),
        ),
      );
    } catch (error) {
      // Give the close frame a moment to arrive so we can read its code.
      if (socket.closeCode == null) {
        await socket.done
            .timeout(const Duration(milliseconds: 300))
            .catchError((Object _) => null);
      }
      final closeCode = socket.closeCode;
      unawaited(socket.close().catchError((Object _) {}));
      throw mapObsError(error, closeCode: closeCode);
    }
  }

  @override
  Future<ObsServerInfo> testConnection(ObsConnectionConfig config) async {
    final session = await _open(config);
    unawaited(session.close());
    return session.info;
  }

  @override
  Future<void> connect(ObsConnectionConfig config) async {
    await _closeSession();
    _retryTimer?.cancel();
    _config = config;
    _wantConnected = true;
    _attempt = 0;
    _setStatus(const ObsConnecting());
    await _connectOnce(rethrowFailure: true);
  }

  Future<void> _connectOnce({bool rethrowFailure = false}) async {
    final config = _config;
    if (config == null || !_wantConnected) return;
    final generation = ++_generation;
    try {
      final session = await _open(config);
      if (generation != _generation || !_wantConnected) {
        await session.close();
        return;
      }
      _session = session;
      session.obs.addFallbackListener(_onRawEvent);
      session.stateSubscription = session.obs.onConnectionStateChanged.listen((
        state,
      ) {
        if (state == ObsConnectionState.disconnected) _onLost(session);
      });
      await session.obs.subscribe(_eventMask);
      _attempt = 0;
      _setStatus(ObsConnected(session.info));
    } on ObsFailure catch (failure) {
      if (generation != _generation || !_wantConnected) return;
      if (failure.isPermanent) {
        _wantConnected = false;
        _setStatus(ObsConnectionFailed(failure));
      } else {
        _scheduleRetry(failure);
      }
      if (rethrowFailure) rethrow;
    }
  }

  void _onLost(_Session session) {
    if (!identical(_session, session)) return;
    _session = null;
    unawaited(session.close());
    if (_wantConnected) {
      _scheduleRetry(const ObsFailure(ObsFailureKind.notConnected));
    } else {
      _setStatus(const ObsDisconnected());
    }
  }

  /// Exponential backoff: 1s, 2s, 4s ... capped at [maxBackoff]. Retries
  /// forever while the user wants to stay connected.
  void _scheduleRetry(ObsFailure failure) {
    _attempt++;
    final seconds = math.min(
      maxBackoff.inSeconds,
      math.pow(2, math.min(_attempt - 1, 10)).toInt(),
    );
    final delay = Duration(seconds: seconds);
    _setStatus(
      ObsReconnecting(
        attempt: _attempt,
        nextRetry: delay,
        lastFailure: failure,
      ),
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(_connectOnce()));
  }

  @override
  void retryNow() {
    if (!_wantConnected || _status is ObsConnected) return;
    _retryTimer?.cancel();
    unawaited(_connectOnce());
  }

  @override
  Future<void> disconnect() async {
    _wantConnected = false;
    _generation++;
    _retryTimer?.cancel();
    await _closeSession();
    _setStatus(const ObsDisconnected());
  }

  Future<void> _closeSession() async {
    final session = _session;
    _session = null;
    if (session != null) await session.close();
  }

  int get _eventMask => _allEvents | (_metersEnabled ? _volumeMetersEvent : 0);

  @override
  Future<void> setVolumeMetersEnabled({required bool enabled}) async {
    if (_metersEnabled == enabled) return;
    _metersEnabled = enabled;
    final session = _session;
    if (session == null) return;
    try {
      await session.obs.subscribe(_eventMask);
    } catch (error) {
      throw mapObsError(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _onRawEvent(Event event) {
    final data = asJsonMap(event.eventData);
    final ObsEvent? mapped = switch (event.eventType) {
      'CurrentProgramSceneChanged' => CurrentSceneChanged(
        data.str('sceneName'),
      ),
      'SceneListChanged' ||
      'SceneCreated' ||
      'SceneRemoved' ||
      'SceneNameChanged' => const SceneListChanged(),
      'SceneItemCreated' ||
      'SceneItemRemoved' ||
      'SceneItemListReindexed' => SceneItemsChanged(data.str('sceneName')),
      'SceneItemEnableStateChanged' => SceneItemEnabledChanged(
        sceneName: data.str('sceneName'),
        itemId: data.integer('sceneItemId'),
        enabled: data.boolean('sceneItemEnabled'),
      ),
      'InputCreated' || 'InputRemoved' => const InputListChanged(),
      'InputNameChanged' => InputRenamed(
        oldName: data.str('oldInputName'),
        newName: data.str('inputName'),
      ),
      'InputMuteStateChanged' => InputMuteChanged(
        data.str('inputName'),
        muted: data.boolean('inputMuted'),
      ),
      'InputVolumeChanged' => InputVolumeChanged(
        data.str('inputName'),
        data.number('inputVolumeMul'),
      ),
      'InputVolumeMeters' => InputVolumeMeters(_parseMeters(data)),
      'StreamStateChanged' => StreamStateChanged(
        active: data.boolean('outputActive'),
        state: data.str('outputState'),
      ),
      'RecordStateChanged' => RecordStateChanged(
        // OBS sends outputActive: false while paused, but it is still
        // recording.
        active:
            data.boolean('outputActive') ||
            data.str('outputState') == 'OBS_WEBSOCKET_OUTPUT_PAUSED',
        state: data.str('outputState'),
      ),
      'ReplayBufferStateChanged' => ReplayBufferStateChanged(
        active: data.boolean('outputActive'),
      ),
      'MediaInputPlaybackStarted' => MediaPlaybackStarted(
        data.str('inputName'),
      ),
      'MediaInputPlaybackEnded' => MediaPlaybackEnded(data.str('inputName')),
      'ExitStarted' => const ObsExiting(),
      _ => null,
    };
    if (mapped != null && !_eventsController.isClosed) {
      _eventsController.add(mapped);
    }
  }

  /// `inputLevelsMul` is `[[magnitude, peak, inputPeak], ...]` per channel.
  static Map<String, double> _parseMeters(JsonMap data) {
    final peaks = <String, double>{};
    for (final input in data.objects('inputs')) {
      var peak = 0.0;
      final channels = input['inputLevelsMul'];
      if (channels is List) {
        for (final channel in channels) {
          if (channel is List && channel.length > 1) {
            final value = channel[1];
            if (value is num && value > peak) peak = value.toDouble();
          }
        }
      }
      peaks[input.str('inputName')] = peak;
    }
    return peaks;
  }

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------

  static Future<JsonMap> _send(
    ObsWebSocket obs,
    String type, [
    JsonMap? data,
  ]) async {
    final response = await obs.sendRequest(
      Request(type, requestData: data, expectResponse: true),
    );
    if (response == null) {
      throw const ObsFailure(ObsFailureKind.notConnected);
    }
    return asJsonMap(response.responseData);
  }

  Future<JsonMap> _call(String type, [JsonMap? data, String? resource]) async {
    final session = _session;
    if (session == null) {
      throw const ObsFailure(ObsFailureKind.notConnected);
    }
    try {
      return await _send(session.obs, type, data).timeout(requestTimeout);
    } on TimeoutException {
      // A request that never answers usually means a dead socket (phone slept,
      // Wi-Fi changed). Drop it so the reconnect loop takes over.
      _onLost(session);
      throw const ObsFailure(ObsFailureKind.timeout);
    } catch (error) {
      throw mapObsError(error, resource: resource);
    }
  }

  @override
  Future<List<ObsScene>> getScenes() async {
    final data = await _call('GetSceneList');
    final scenes = data
        .objects('scenes')
        .map(
          (s) => ObsScene(
            name: s.str('sceneName'),
            index: s.integer('sceneIndex'),
          ),
        )
        .toList();
    // OBS lists the top scene with the highest index.
    scenes.sort((a, b) => b.index.compareTo(a.index));
    return scenes;
  }

  @override
  Future<String> getCurrentProgramScene() async {
    final data = await _call('GetCurrentProgramScene');
    return data.str('currentProgramSceneName', data.str('sceneName'));
  }

  @override
  Future<void> setCurrentProgramScene(String sceneName) =>
      _call('SetCurrentProgramScene', {'sceneName': sceneName}, sceneName);

  @override
  Future<List<ObsSceneItem>> getSceneItems(String sceneName) async {
    final data = await _call('GetSceneItemList', {
      'sceneName': sceneName,
    }, sceneName);
    return data
        .objects('sceneItems')
        .map(
          (item) => ObsSceneItem(
            id: item.integer('sceneItemId'),
            sourceName: item.str('sourceName'),
            enabled: item.boolean('sceneItemEnabled'),
            inputKind: item.strOrNull('inputKind'),
          ),
        )
        .toList();
  }

  @override
  Future<void> setSceneItemEnabled(
    String sceneName,
    int itemId, {
    required bool enabled,
  }) => _call('SetSceneItemEnabled', {
    'sceneName': sceneName,
    'sceneItemId': itemId,
    'sceneItemEnabled': enabled,
  }, sceneName);

  @override
  Future<List<ObsInput>> getInputs() async {
    final data = await _call('GetInputList');
    return data
        .objects('inputs')
        .map(
          (i) => ObsInput(
            name: i.str('inputName'),
            kind: i.str('unversionedInputKind', i.str('inputKind')),
          ),
        )
        .toList();
  }

  @override
  Future<List<ObsAudioInput>> getAudioInputs() async {
    final inputs = await getInputs();
    // There is no "has audio" flag in every OBS version, so ask each input
    // for its volume: inputs without audio answer with an error.
    final results = await Future.wait(
      inputs.map((input) async {
        try {
          final volume = await _call('GetInputVolume', {
            'inputName': input.name,
          });
          final mute = await _call('GetInputMute', {'inputName': input.name});
          return ObsAudioInput(
            name: input.name,
            volumeMul: volume.number('inputVolumeMul', 1),
            muted: mute.boolean('inputMuted'),
          );
        } on ObsFailure catch (failure) {
          if (failure.isConnectionProblem) rethrow;
          return null;
        }
      }),
    );
    return results.nonNulls.toList();
  }

  @override
  Future<bool> getInputMute(String inputName) async {
    final data = await _call('GetInputMute', {
      'inputName': inputName,
    }, inputName);
    return data.boolean('inputMuted');
  }

  @override
  Future<void> setInputMute(String inputName, {required bool muted}) => _call(
    'SetInputMute',
    {'inputName': inputName, 'inputMuted': muted},
    inputName,
  );

  @override
  Future<void> toggleInputMute(String inputName) =>
      _call('ToggleInputMute', {'inputName': inputName}, inputName);

  @override
  Future<double> getInputVolume(String inputName) async {
    final data = await _call('GetInputVolume', {
      'inputName': inputName,
    }, inputName);
    return data.number('inputVolumeMul', 1);
  }

  @override
  Future<void> setInputVolume(String inputName, double volumeMul) => _call(
    'SetInputVolume',
    {'inputName': inputName, 'inputVolumeMul': volumeMul.clamp(0.0, 20.0)},
    inputName,
  );

  @override
  Future<ObsStreamStatus> getStreamStatus() async {
    final d = await _call('GetStreamStatus');
    return ObsStreamStatus(
      active: d.boolean('outputActive'),
      reconnecting: d.boolean('outputReconnecting'),
      duration: Duration(milliseconds: d.integer('outputDuration')),
      congestion: d.number('outputCongestion'),
      bytes: d.integer('outputBytes'),
      skippedFrames: d.integer('outputSkippedFrames'),
      totalFrames: d.integer('outputTotalFrames'),
    );
  }

  @override
  Future<ObsRecordStatus> getRecordStatus() async {
    final d = await _call('GetRecordStatus');
    return ObsRecordStatus(
      active: d.boolean('outputActive'),
      paused: d.boolean('outputPaused'),
      duration: Duration(milliseconds: d.integer('outputDuration')),
      bytes: d.integer('outputBytes'),
    );
  }

  @override
  Future<bool> getReplayBufferActive() async {
    try {
      final d = await _call('GetReplayBufferStatus');
      return d.boolean('outputActive');
    } on ObsFailure catch (failure) {
      if (failure.isConnectionProblem) rethrow;
      return false; // Replay buffer not enabled in OBS settings.
    }
  }

  @override
  Future<void> startStream() => _call('StartStream');

  @override
  Future<void> stopStream() => _call('StopStream');

  @override
  Future<void> toggleStream() => _call('ToggleStream');

  @override
  Future<void> startRecord() => _call('StartRecord');

  @override
  Future<void> stopRecord() => _call('StopRecord');

  @override
  Future<void> toggleRecord() => _call('ToggleRecord');

  @override
  Future<void> toggleRecordPause() async {
    final before = await getRecordStatus();
    await _call('ToggleRecordPause');
    // OBS answers "paused" even when it can't pause (recording sharing the
    // live encoder), so check that it really changed.
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if ((await getRecordStatus()).paused != before.paused) return;
    }
    throw const ObsFailure(ObsFailureKind.recordPauseUnsupported);
  }

  @override
  Future<void> saveReplayBuffer() async {
    try {
      await _call('SaveReplayBuffer');
    } on ObsFailure catch (failure) {
      // "Replay buffer is not available" (off in settings) or not started.
      if (failure.kind == ObsFailureKind.invalidState ||
          failure.kind == ObsFailureKind.outputNotActive) {
        throw ObsFailure(
          ObsFailureKind.replayBufferOff,
          detail: failure.detail,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> getHotkeys() async {
    final data = await _call('GetHotkeyList');
    return data.strings('hotkeys');
  }

  @override
  Future<void> triggerHotkey(String hotkeyName) =>
      _call('TriggerHotkeyByName', {'hotkeyName': hotkeyName}, hotkeyName);

  @override
  Future<ObsStats> getStats() async {
    final d = await _call('GetStats');
    return ObsStats(
      cpuUsage: d.number('cpuUsage'),
      memoryUsageMb: d.number('memoryUsage'),
      activeFps: d.number('activeFps'),
      averageFrameRenderTimeMs: d.number('averageFrameRenderTime'),
      renderSkippedFrames: d.integer('renderSkippedFrames'),
      renderTotalFrames: d.integer('renderTotalFrames'),
      outputSkippedFrames: d.integer('outputSkippedFrames'),
      outputTotalFrames: d.integer('outputTotalFrames'),
    );
  }

  @override
  Future<void> triggerMediaAction(String inputName, ObsMediaAction action) =>
      _call('TriggerMediaInputAction', {
        'inputName': inputName,
        'mediaAction': action.protocolValue,
      }, inputName);

  @override
  Future<ObsMediaState> getMediaState(String inputName) async {
    final data = await _call('GetMediaInputStatus', {
      'inputName': inputName,
    }, inputName);
    return ObsMediaState.fromProtocol(data.strOrNull('mediaState'));
  }

  @override
  Future<void> setMediaLooping(String inputName, {required bool loop}) =>
      _call('SetInputSettings', {
        'inputName': inputName,
        'inputSettings': {'looping': loop},
        'overlay': true,
      }, inputName);

  @override
  Future<MediaSourceSetupResult> setupMediaSource(
    MediaSourceRequest request,
  ) async {
    final name = request.inputName;
    final settings = <String, Object?>{
      'is_local_file': true,
      'local_file': request.filePath,
      'looping': request.loop,
      // Free the file while the scene is not shown, and never auto-play
      // when switching scenes: the pad decides when to play.
      'close_when_inactive': true,
      'restart_on_activate': false,
    };

    final existing = await getInputs();
    final exists = existing.any((input) => input.name == name);
    final MediaSourceSetupResult result;
    if (exists) {
      await _call('SetInputSettings', {
        'inputName': name,
        'inputSettings': settings,
        'overlay': true,
      }, name);
      await _ensureInScene(request.sceneName, name);
      result = MediaSourceSetupResult.updated;
    } else {
      await _call('CreateInput', {
        'sceneName': request.sceneName,
        'inputName': name,
        'inputKind': 'ffmpeg_source',
        'inputSettings': settings,
        'sceneItemEnabled': true,
      }, request.sceneName);
      result = MediaSourceSetupResult.created;
    }

    for (final scene in request.alsoAddToScenes) {
      if (scene != request.sceneName) await _ensureInScene(scene, name);
    }

    // Make sure the sound reaches the live: unmuted, on track 1 (the track
    // used by streaming) and, optionally, also on the PC headphones.
    await _call('SetInputMute', {'inputName': name, 'inputMuted': false}, name);
    await _call('SetInputAudioTracks', {
      'inputName': name,
      'inputAudioTracks': {'1': true},
    }, name);
    if (request.monitor) {
      await _call('SetInputAudioMonitorType', {
        'inputName': name,
        'monitorType': 'OBS_MONITORING_TYPE_MONITOR_AND_OUTPUT',
      }, name);
    }
    // A freshly created media source may start playing on its own.
    await _call('TriggerMediaInputAction', {
      'inputName': name,
      'mediaAction': ObsMediaAction.stop.protocolValue,
    }, name);
    // The stop is applied asynchronously (~100 ms). A play sent before that
    // is cut off right away, so wait until the source really stopped.
    for (var i = 0; i < 20; i++) {
      final state = await getMediaState(name);
      if (state != ObsMediaState.playing && state != ObsMediaState.opening) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return result;
  }

  Future<void> _ensureInScene(String sceneName, String sourceName) async {
    try {
      await _call('GetSceneItemId', {
        'sceneName': sceneName,
        'sourceName': sourceName,
      }, sceneName);
    } on ObsFailure catch (failure) {
      if (failure.kind != ObsFailureKind.resourceNotFound) rethrow;
      await _call('CreateSceneItem', {
        'sceneName': sceneName,
        'sourceName': sourceName,
        'sceneItemEnabled': true,
      }, sceneName);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _eventsController.close();
  }
}

class _Session {
  _Session({required this.obs, required this.socket, required this.info});

  final ObsWebSocket obs;
  final WebSocket socket;
  final ObsServerInfo info;
  StreamSubscription<ObsConnectionState>? stateSubscription;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await stateSubscription?.cancel();
    try {
      await obs.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      await socket.close().catchError((Object _) {});
    }
  }
}
