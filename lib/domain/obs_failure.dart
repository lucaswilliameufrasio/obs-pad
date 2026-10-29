/// Every problem the app can run into while talking to OBS, already
/// translated from network/protocol errors into something a person can act on.
enum ObsFailureKind {
  /// OBS rejected the password (WebSocket close code 4009).
  wrongPassword,

  /// The PC answered but nothing listens on the port: OBS is closed, the
  /// WebSocket server is turned off or the port is different.
  serverOff,

  /// Nobody answered in time: wrong IP or a firewall silently dropping 4455.
  timeout,

  /// The phone cannot reach that network at all (different Wi-Fi, VPN off).
  unreachable,

  /// The address typed is not a valid IP/host name.
  invalidAddress,

  /// Something answered on that port, but it is not OBS WebSocket 5.
  notObs,

  /// OBS is too old (no WebSocket 5.x protocol).
  unsupportedVersion,

  /// A command was sent while there is no connection.
  notConnected,

  /// A scene, source or input with that name does not exist in OBS.
  resourceNotFound,

  /// Trying to create something that already exists.
  alreadyExists,

  /// OBS accepted the pause but did not pause: the recording shares the
  /// live encoder ("Recording quality: same as stream"), which can't pause.
  recordPauseUnsupported,

  /// Replay buffer turned off in the OBS settings, or not started.
  replayBufferOff,

  /// OBS accepted "play" but nothing played: the media source is not in the
  /// scene on air, and OBS only plays sources of active scenes.
  soundNotOnAir,

  /// Live/recording is already running.
  outputAlreadyActive,

  /// Live/recording is not running.
  outputNotActive,

  /// The output is disabled in OBS (e.g. replay buffer not enabled).
  outputDisabled,

  /// The resource exists but cannot do that (e.g. volume of a video source).
  invalidState,

  /// The input type is not available in this OBS.
  invalidInputKind,

  /// OBS understood the command but could not do it.
  requestFailed,

  unknown,
}

class ObsFailure implements Exception {
  const ObsFailure(this.kind, {this.resource, this.detail});

  final ObsFailureKind kind;

  /// Name of the scene/source/input involved, when known.
  final String? resource;

  /// Raw technical detail, shown only in "details" sections.
  final String? detail;

  bool get isConnectionProblem => switch (kind) {
    ObsFailureKind.wrongPassword ||
    ObsFailureKind.serverOff ||
    ObsFailureKind.timeout ||
    ObsFailureKind.unreachable ||
    ObsFailureKind.invalidAddress ||
    ObsFailureKind.notObs ||
    ObsFailureKind.unsupportedVersion ||
    ObsFailureKind.notConnected => true,
    _ => false,
  };

  /// Retrying will not help until the user changes something.
  bool get isPermanent =>
      kind == ObsFailureKind.wrongPassword ||
      kind == ObsFailureKind.invalidAddress ||
      kind == ObsFailureKind.unsupportedVersion;

  @override
  String toString() =>
      'ObsFailure($kind, resource: $resource, detail: $detail)';
}
