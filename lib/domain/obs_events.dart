/// Events coming from OBS, already decoupled from the protocol package.
sealed class ObsEvent {
  const ObsEvent();
}

class CurrentSceneChanged extends ObsEvent {
  const CurrentSceneChanged(this.sceneName);
  final String sceneName;
}

class SceneListChanged extends ObsEvent {
  const SceneListChanged();
}

class SceneItemsChanged extends ObsEvent {
  const SceneItemsChanged(this.sceneName);
  final String sceneName;
}

class SceneItemEnabledChanged extends ObsEvent {
  const SceneItemEnabledChanged({
    required this.sceneName,
    required this.itemId,
    required this.enabled,
  });

  final String sceneName;
  final int itemId;
  final bool enabled;
}

class InputListChanged extends ObsEvent {
  const InputListChanged();
}

class InputRenamed extends ObsEvent {
  const InputRenamed({required this.oldName, required this.newName});
  final String oldName;
  final String newName;
}

class InputMuteChanged extends ObsEvent {
  const InputMuteChanged(this.inputName, {required this.muted});
  final String inputName;
  final bool muted;
}

class InputVolumeChanged extends ObsEvent {
  const InputVolumeChanged(this.inputName, this.volumeMul);
  final String inputName;
  final double volumeMul;
}

/// Peak level (multiplier, 0..1+) per input, every ~50 ms.
class InputVolumeMeters extends ObsEvent {
  const InputVolumeMeters(this.peaks);
  final Map<String, double> peaks;
}

class StreamStateChanged extends ObsEvent {
  const StreamStateChanged({required this.active, required this.state});
  final bool active;
  final String state;

  bool get reconnecting => state == 'OBS_WEBSOCKET_OUTPUT_RECONNECTING';
}

class RecordStateChanged extends ObsEvent {
  const RecordStateChanged({required this.active, required this.state});
  final bool active;
  final String state;

  bool get paused => state == 'OBS_WEBSOCKET_OUTPUT_PAUSED';
  bool get resumed => state == 'OBS_WEBSOCKET_OUTPUT_RESUMED';
}

class ReplayBufferStateChanged extends ObsEvent {
  const ReplayBufferStateChanged({required this.active});
  final bool active;
}

class MediaPlaybackStarted extends ObsEvent {
  const MediaPlaybackStarted(this.inputName);
  final String inputName;
}

class MediaPlaybackEnded extends ObsEvent {
  const MediaPlaybackEnded(this.inputName);
  final String inputName;
}

class ObsExiting extends ObsEvent {
  const ObsExiting();
}
