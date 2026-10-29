import 'dart:async';

import 'package:obs_pad/domain/obs_events.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_pad/domain/obs_models.dart';
import 'package:obs_pad/domain/obs_repository.dart';

/// In-memory OBS used by widget tests. Records every command it receives.
class FakeObsRepository implements ObsRepository {
  FakeObsRepository({
    this.testResult = const ObsServerInfo(
      obsVersion: '31.0.0',
      webSocketVersion: '5.5.0',
      rpcVersion: 1,
    ),
  });

  /// What [testConnection] returns: an [ObsServerInfo] or an [ObsFailure].
  Object testResult;
  ObsConnectionConfig? lastTestedConfig;

  final calls = <String>[];
  final statusController = StreamController<ObsConnectionStatus>.broadcast();
  final eventsController = StreamController<ObsEvent>.broadcast();

  List<ObsScene> scenes = const [
    ObsScene(name: 'Começando', index: 2),
    ObsScene(name: 'Jogo', index: 1),
    ObsScene(name: 'Intervalo', index: 0),
  ];
  String currentScene = 'Começando';
  Map<String, double> volumes = {'Mic': 1, 'Música': 0.5};
  Map<String, bool> mutes = {'Mic': false, 'Música': false};

  ObsConnectionStatus _status = const ObsDisconnected();

  void emit(ObsEvent event) => eventsController.add(event);

  void _setStatus(ObsConnectionStatus status) {
    _status = status;
    statusController.add(status);
  }

  @override
  ObsConnectionStatus get status => _status;

  @override
  Stream<ObsConnectionStatus> get statusChanges => statusController.stream;

  @override
  Stream<ObsEvent> get events => eventsController.stream;

  @override
  Future<ObsServerInfo> testConnection(ObsConnectionConfig config) async {
    lastTestedConfig = config;
    calls.add('testConnection ${config.host}:${config.port}');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final result = testResult;
    if (result is ObsFailure) throw result;
    return result as ObsServerInfo;
  }

  @override
  Future<void> connect(ObsConnectionConfig config) async {
    calls.add('connect ${config.host}');
    _setStatus(
      ObsConnected(
        testResult is ObsServerInfo
            ? testResult as ObsServerInfo
            : const ObsServerInfo(
                obsVersion: '31',
                webSocketVersion: '5',
                rpcVersion: 1,
              ),
      ),
    );
  }

  @override
  Future<void> disconnect() async => _setStatus(const ObsDisconnected());

  @override
  void retryNow() => calls.add('retryNow');

  @override
  Future<void> setVolumeMetersEnabled({required bool enabled}) async =>
      calls.add('meters $enabled');

  @override
  Future<List<ObsScene>> getScenes() async => scenes;

  @override
  Future<String> getCurrentProgramScene() async => currentScene;

  @override
  Future<void> setCurrentProgramScene(String sceneName) async {
    calls.add('scene $sceneName');
    if (!scenes.any((s) => s.name == sceneName)) {
      throw ObsFailure(ObsFailureKind.resourceNotFound, resource: sceneName);
    }
    currentScene = sceneName;
    emit(CurrentSceneChanged(sceneName));
  }

  @override
  Future<List<ObsSceneItem>> getSceneItems(String sceneName) async => const [
    ObsSceneItem(id: 1, sourceName: 'Câmera', enabled: true),
    ObsSceneItem(id: 2, sourceName: 'Alerta', enabled: false),
  ];

  @override
  Future<void> setSceneItemEnabled(
    String sceneName,
    int itemId, {
    required bool enabled,
  }) async => calls.add('item $sceneName $itemId $enabled');

  @override
  Future<List<ObsInput>> getInputs() async => [
    for (final name in volumes.keys)
      ObsInput(name: name, kind: 'wasapi_input_capture'),
    const ObsInput(name: 'Buzina', kind: 'ffmpeg_source'),
  ];

  @override
  Future<List<ObsAudioInput>> getAudioInputs() async => [
    for (final e in volumes.entries)
      ObsAudioInput(
        name: e.key,
        volumeMul: e.value,
        muted: mutes[e.key] ?? false,
      ),
  ];

  @override
  Future<bool> getInputMute(String inputName) async =>
      mutes[inputName] ?? false;

  @override
  Future<void> setInputMute(String inputName, {required bool muted}) async {
    calls.add('mute $inputName $muted');
    mutes[inputName] = muted;
  }

  @override
  Future<void> toggleInputMute(String inputName) async {
    calls.add('toggleMute $inputName');
    mutes[inputName] = !(mutes[inputName] ?? false);
  }

  @override
  Future<double> getInputVolume(String inputName) async =>
      volumes[inputName] ?? 1;

  @override
  Future<void> setInputVolume(String inputName, double volumeMul) async {
    calls.add('volume $inputName ${volumeMul.toStringAsFixed(2)}');
    volumes[inputName] = volumeMul;
  }

  @override
  Future<ObsStreamStatus> getStreamStatus() async => ObsStreamStatus.inactive;

  @override
  Future<ObsRecordStatus> getRecordStatus() async => ObsRecordStatus.inactive;

  @override
  Future<bool> getReplayBufferActive() async => false;

  @override
  Future<void> startStream() async => calls.add('startStream');

  @override
  Future<void> stopStream() async => calls.add('stopStream');

  @override
  Future<void> toggleStream() async => calls.add('toggleStream');

  @override
  Future<void> startRecord() async => calls.add('startRecord');

  @override
  Future<void> stopRecord() async => calls.add('stopRecord');

  @override
  Future<void> toggleRecord() async => calls.add('toggleRecord');

  @override
  Future<void> toggleRecordPause() async => calls.add('toggleRecordPause');

  @override
  Future<void> saveReplayBuffer() async => calls.add('saveReplay');

  @override
  Future<List<String>> getHotkeys() async => const ['OBSBasic.StartStreaming'];

  @override
  Future<void> triggerHotkey(String hotkeyName) async =>
      calls.add('hotkey $hotkeyName');

  @override
  Future<ObsStats> getStats() async => const ObsStats(
    cpuUsage: 10,
    memoryUsageMb: 500,
    activeFps: 60,
    averageFrameRenderTimeMs: 2,
    renderSkippedFrames: 0,
    renderTotalFrames: 1000,
    outputSkippedFrames: 0,
    outputTotalFrames: 1000,
  );

  @override
  Future<void> triggerMediaAction(
    String inputName,
    ObsMediaAction action,
  ) async {
    calls.add('media $inputName ${action.name}');
    // Like OBS, when the source is in the scene on air.
    if (action == ObsMediaAction.restart && playsOnRestart) {
      scheduleMicrotask(() => emit(MediaPlaybackStarted(inputName)));
    }
  }

  /// False = the sound is not in the scene on air: OBS emits nothing.
  bool playsOnRestart = true;

  @override
  Future<void> addInputToScenes(
    String inputName,
    List<String> sceneNames,
  ) async => calls.add('addToScenes $inputName ${sceneNames.join(',')}');

  @override
  Future<ObsMediaState> getMediaState(String inputName) async =>
      ObsMediaState.stopped;

  @override
  Future<void> setMediaLooping(String inputName, {required bool loop}) async =>
      calls.add('loop $inputName $loop');

  @override
  Future<MediaSourceSetupResult> setupMediaSource(
    MediaSourceRequest request,
  ) async {
    calls.add('setupMedia ${request.inputName} ${request.filePath}');
    return MediaSourceSetupResult.created;
  }
}
