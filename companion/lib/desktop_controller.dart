import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import 'system.dart';

const appVersion = '0.1.0';

enum EnableResult { enabled, obsRunning, failed }

/// State of the desktop app: OBS settings, the server for the phone and
/// what the phone did.
class DesktopController extends ChangeNotifier {
  DesktopController({
    required this.system,
    required this.locateSettings,
    this.port = defaultCompanionPort,
    this.refreshEvery = const Duration(seconds: 3),
  });

  final DesktopSystem system;
  final ObsSettingsFile? Function() locateSettings;

  /// 0 in tests (any free port).
  final int port;
  final Duration refreshEvery;

  ObsSettingsFile? settingsFile;
  ObsWebSocketSettings? settings;
  bool obsRunning = false;
  List<LanAddress> addresses = const [];
  int soundCount = 0;

  /// The port is taken (another copy of this app, most likely).
  bool serverFailed = false;
  final List<CompanionActivity> activity = [];

  CompanionServer? _server;
  Timer? _timer;
  bool _disposed = false;

  CompanionServer? get server => _server;
  bool get readyForPhone => settings?.readyForPhone ?? false;

  /// What the phone scans: the first home-network address.
  ConnectionLink? get connectionLink {
    final current = settings;
    if (current == null || !current.readyForPhone || addresses.isEmpty) {
      return null;
    }
    return ConnectionLink(
      host: addresses.first.ip,
      port: current.port,
      password: current.password,
      name: system.computerName,
    );
  }

  Future<void> start() async {
    await refresh();
    final server = CompanionServer(
      // Only with a password: without it anyone on the Wi-Fi could send
      // files.
      secret: () {
        final current = settingsFile?.read();
        return current != null && current.authRequired
            ? current.password
            : null;
      },
      soundsDir: system.soundsDir,
      announcement: _announcement,
      port: port,
      onActivity: _onActivity,
    );
    try {
      await server.start();
      _server = server;
    } on SocketException {
      serverFailed = true;
      await server.stop();
    }
    _timer = Timer.periodic(refreshEvery, (_) => unawaited(refresh()));
    _notify();
  }

  CompanionAnnouncement _announcement() {
    final current = settings;
    return CompanionAnnouncement(
      name: system.computerName,
      obsPort: current?.port ?? 4455,
      companionPort: _server?.httpPort ?? port,
      version: appVersion,
      obsServerEnabled: current?.enabled ?? false,
    );
  }

  void _onActivity(CompanionActivity event) {
    activity.insert(0, event);
    if (activity.length > 30) activity.removeLast();
    if (event.kind == CompanionActivityKind.uploaded) {
      unawaited(refresh());
    }
    _notify();
  }

  Future<void> refresh() async {
    settingsFile ??= locateSettings();
    settings = settingsFile?.read();
    final (running, lan, sounds) = await (
      system.isObsRunning(),
      system.lanAddresses(),
      _countSounds(),
    ).wait;
    obsRunning = running;
    addresses = lan;
    soundCount = sounds;
    _notify();
  }

  Future<int> _countSounds() async {
    final dir = system.soundsDir;
    if (!dir.existsSync()) return 0;
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && safeSoundFileName(entity.path) != null) count++;
    }
    return count;
  }

  /// Turns on the OBS WebSocket server with a password. OBS must be closed,
  /// or it overwrites the change when it exits.
  Future<EnableResult> enableForPhone() async {
    obsRunning = await system.isObsRunning();
    if (obsRunning) {
      _notify();
      return EnableResult.obsRunning;
    }
    final file = settingsFile ?? locateSettings();
    if (file == null) return EnableResult.failed;
    try {
      settingsFile = file;
      settings = await file.enableForPhone();
      _notify();
      return EnableResult.enabled;
    } on FileSystemException {
      return EnableResult.failed;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_server?.stop());
    super.dispose();
  }
}
