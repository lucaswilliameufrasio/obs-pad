import 'obs_failure.dart';

const int defaultObsPort = 4455;

/// What is needed to open a connection. The password never leaves memory and
/// secure storage.
class ObsConnectionConfig {
  const ObsConnectionConfig({
    required this.host,
    this.port = defaultObsPort,
    this.password = '',
    this.timeout = const Duration(seconds: 6),
  });

  final String host;
  final int port;
  final String password;
  final Duration timeout;

  Uri get uri => Uri(scheme: 'ws', host: host.trim(), port: port);
}

class ObsServerInfo {
  const ObsServerInfo({
    required this.obsVersion,
    required this.webSocketVersion,
    required this.rpcVersion,
  });

  final String obsVersion;
  final String webSocketVersion;
  final int rpcVersion;

  int get obsMajorVersion => int.tryParse(obsVersion.split('.').first) ?? 0;
}

sealed class ObsConnectionStatus {
  const ObsConnectionStatus();
}

class ObsDisconnected extends ObsConnectionStatus {
  const ObsDisconnected();
}

class ObsConnecting extends ObsConnectionStatus {
  const ObsConnecting();
}

class ObsConnected extends ObsConnectionStatus {
  const ObsConnected(this.info);
  final ObsServerInfo info;
}

class ObsReconnecting extends ObsConnectionStatus {
  const ObsReconnecting({
    required this.attempt,
    required this.nextRetry,
    this.lastFailure,
  });

  final int attempt;
  final Duration nextRetry;
  final ObsFailure? lastFailure;
}

class ObsConnectionFailed extends ObsConnectionStatus {
  const ObsConnectionFailed(this.failure);
  final ObsFailure failure;
}

class ObsScene {
  const ObsScene({required this.name, required this.index});
  final String name;
  final int index;
}

class ObsSceneItem {
  const ObsSceneItem({
    required this.id,
    required this.sourceName,
    required this.enabled,
    this.inputKind,
  });

  final int id;
  final String sourceName;
  final bool enabled;
  final String? inputKind;
}

class ObsInput {
  const ObsInput({required this.name, required this.kind});
  final String name;
  final String kind;

  bool get isMediaSource => kind == 'ffmpeg_source' || kind == 'vlc_source';
}

class ObsAudioInput {
  const ObsAudioInput({
    required this.name,
    required this.volumeMul,
    required this.muted,
  });

  final String name;
  final double volumeMul;
  final bool muted;
}

class ObsStats {
  const ObsStats({
    required this.cpuUsage,
    required this.memoryUsageMb,
    required this.activeFps,
    required this.averageFrameRenderTimeMs,
    required this.renderSkippedFrames,
    required this.renderTotalFrames,
    required this.outputSkippedFrames,
    required this.outputTotalFrames,
  });

  final double cpuUsage;
  final double memoryUsageMb;
  final double activeFps;
  final double averageFrameRenderTimeMs;
  final int renderSkippedFrames;
  final int renderTotalFrames;
  final int outputSkippedFrames;
  final int outputTotalFrames;
}

class ObsStreamStatus {
  const ObsStreamStatus({
    required this.active,
    required this.reconnecting,
    required this.duration,
    required this.congestion,
    required this.bytes,
    required this.skippedFrames,
    required this.totalFrames,
  });

  static const inactive = ObsStreamStatus(
    active: false,
    reconnecting: false,
    duration: Duration.zero,
    congestion: 0,
    bytes: 0,
    skippedFrames: 0,
    totalFrames: 0,
  );

  final bool active;
  final bool reconnecting;
  final Duration duration;

  /// 0..1
  final double congestion;
  final int bytes;
  final int skippedFrames;
  final int totalFrames;
}

class ObsRecordStatus {
  const ObsRecordStatus({
    required this.active,
    required this.paused,
    required this.duration,
    required this.bytes,
  });

  static const inactive = ObsRecordStatus(
    active: false,
    paused: false,
    duration: Duration.zero,
    bytes: 0,
  );

  final bool active;
  final bool paused;
  final Duration duration;
  final int bytes;
}

/// Subset of `ObsMediaInputAction` used by the app.
enum ObsMediaAction {
  play('OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY'),
  pause('OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE'),
  stop('OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP'),
  restart('OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART');

  const ObsMediaAction(this.protocolValue);
  final String protocolValue;
}

enum ObsMediaState {
  none,
  playing,
  opening,
  buffering,
  paused,
  stopped,
  ended,
  error;

  static ObsMediaState fromProtocol(String? value) => switch (value) {
    'OBS_MEDIA_STATE_PLAYING' => playing,
    'OBS_MEDIA_STATE_OPENING' => opening,
    'OBS_MEDIA_STATE_BUFFERING' => buffering,
    'OBS_MEDIA_STATE_PAUSED' => paused,
    'OBS_MEDIA_STATE_STOPPED' => stopped,
    'OBS_MEDIA_STATE_ENDED' => ended,
    'OBS_MEDIA_STATE_ERROR' => error,
    _ => none,
  };
}

/// Request for the "Adicionar som" assistant.
class MediaSourceRequest {
  const MediaSourceRequest({
    required this.inputName,
    required this.filePath,
    required this.sceneName,
    this.alsoAddToScenes = const [],
    this.loop = false,
    this.monitor = true,
  });

  final String inputName;
  final String filePath;
  final String sceneName;
  final List<String> alsoAddToScenes;
  final bool loop;

  /// Also play on the PC headphones (monitor and output).
  final bool monitor;
}

enum MediaSourceSetupResult { created, updated }
