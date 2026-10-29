import 'obs_events.dart';
import 'obs_models.dart';

/// The only door between the app and OBS. The UI never sees the
/// obs_websocket package; every error thrown here is an `ObsFailure`.
abstract interface class ObsRepository {
  ObsConnectionStatus get status;
  Stream<ObsConnectionStatus> get statusChanges;
  Stream<ObsEvent> get events;

  /// Opens a throwaway connection, reads the version and closes it.
  Future<ObsServerInfo> testConnection(ObsConnectionConfig config);

  /// Keeps a connection open, reconnecting with backoff when it drops.
  Future<void> connect(ObsConnectionConfig config);
  Future<void> disconnect();

  /// Skips the backoff wait of a pending reconnect.
  void retryNow();

  /// High-volume `InputVolumeMeters` events; only enable while needed.
  Future<void> setVolumeMetersEnabled({required bool enabled});

  // Scenes
  Future<List<ObsScene>> getScenes();
  Future<String> getCurrentProgramScene();
  Future<void> setCurrentProgramScene(String sceneName);
  Future<List<ObsSceneItem>> getSceneItems(String sceneName);
  Future<void> setSceneItemEnabled(
    String sceneName,
    int itemId, {
    required bool enabled,
  });

  // Inputs / audio
  Future<List<ObsInput>> getInputs();
  Future<List<ObsAudioInput>> getAudioInputs();
  Future<bool> getInputMute(String inputName);
  Future<void> setInputMute(String inputName, {required bool muted});
  Future<void> toggleInputMute(String inputName);
  Future<double> getInputVolume(String inputName);
  Future<void> setInputVolume(String inputName, double volumeMul);

  // Outputs
  Future<ObsStreamStatus> getStreamStatus();
  Future<ObsRecordStatus> getRecordStatus();
  Future<bool> getReplayBufferActive();
  Future<void> startStream();
  Future<void> stopStream();
  Future<void> toggleStream();
  Future<void> startRecord();
  Future<void> stopRecord();
  Future<void> toggleRecord();
  Future<void> toggleRecordPause();
  Future<void> saveReplayBuffer();

  // Misc
  Future<List<String>> getHotkeys();
  Future<void> triggerHotkey(String hotkeyName);
  Future<ObsStats> getStats();

  // Media (soundboard)
  Future<void> triggerMediaAction(String inputName, ObsMediaAction action);
  Future<ObsMediaState> getMediaState(String inputName);
  Future<void> setMediaLooping(String inputName, {required bool loop});
  Future<MediaSourceSetupResult> setupMediaSource(MediaSourceRequest request);

  /// Adds an existing source to each scene that does not have it yet.
  Future<void> addInputToScenes(String inputName, List<String> sceneNames);
}
