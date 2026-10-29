import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// The OBS WebSocket server settings, as OBS stores them.
class ObsWebSocketSettings {
  const ObsWebSocketSettings({
    required this.enabled,
    required this.port,
    required this.authRequired,
    required this.password,
  });

  final bool enabled;
  final int port;
  final bool authRequired;
  final String password;

  /// Ready for the phone: server on and protected by a password.
  bool get readyForPhone => enabled && authRequired && password.isNotEmpty;
}

/// `plugin_config/obs-websocket/config.json` inside the OBS settings folder
/// (OBS 28 or newer).
class ObsSettingsFile {
  ObsSettingsFile(this.file);

  final File file;

  static const _relative = ['plugin_config', 'obs-websocket', 'config.json'];

  /// OBS settings folders for this computer, most likely first.
  static List<String> candidateDirs({
    String? operatingSystem,
    Map<String, String>? environment,
  }) {
    final os = operatingSystem ?? Platform.operatingSystem;
    final env = environment ?? Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    switch (os) {
      case 'windows':
        final appData = env['APPDATA'];
        return [
          if (appData != null) p.windows.join(appData, 'obs-studio'),
          if (home.isNotEmpty)
            p.windows.join(home, 'AppData', 'Roaming', 'obs-studio'),
        ];
      case 'macos':
        return [
          p.posix.join(home, 'Library', 'Application Support', 'obs-studio'),
        ];
      default:
        final xdg = env['XDG_CONFIG_HOME'];
        return [
          if (xdg != null && xdg.isNotEmpty) p.posix.join(xdg, 'obs-studio'),
          p.posix.join(home, '.config', 'obs-studio'),
          // Flatpak install.
          p.posix.join(
            home,
            '.var',
            'app',
            'com.obsproject.Studio',
            'config',
            'obs-studio',
          ),
        ];
    }
  }

  /// The settings file of the OBS installed here, or null if OBS was never
  /// opened (the folder is created on the first run).
  static ObsSettingsFile? locate({
    String? operatingSystem,
    Map<String, String>? environment,
  }) {
    final os = operatingSystem ?? Platform.operatingSystem;
    final context = os == 'windows' ? p.windows : p.posix;
    for (final dir in candidateDirs(
      operatingSystem: os,
      environment: environment,
    )) {
      if (Directory(dir).existsSync()) {
        return ObsSettingsFile(File(context.joinAll([dir, ..._relative])));
      }
    }
    return null;
  }

  /// Settings in [dir] (an OBS settings folder).
  factory ObsSettingsFile.inDir(String dir) =>
      ObsSettingsFile(File(p.joinAll([dir, ..._relative])));

  /// Current settings; OBS defaults when the file does not exist yet.
  ObsWebSocketSettings read() {
    final json = _readJson();
    return ObsWebSocketSettings(
      enabled: json['server_enabled'] as bool? ?? false,
      port: (json['server_port'] as num?)?.toInt() ?? 4455,
      authRequired: json['auth_required'] as bool? ?? true,
      password: json['server_password'] as String? ?? '',
    );
  }

  /// Turns the server on with a password (keeps the current one, or creates
  /// one). OBS must be closed: it rewrites this file when it exits.
  Future<ObsWebSocketSettings> enableForPhone({int port = 4455}) async {
    final json = _readJson();
    final current = json['server_password'] as String? ?? '';
    final password = current.isNotEmpty ? current : generatePassword();
    json
      ..['server_enabled'] = true
      ..['auth_required'] = true
      ..['server_password'] = password
      ..['server_port'] = (json['server_port'] as num?)?.toInt() ?? port
      // Skip OBS's own "here is your password" popup on the next start.
      ..['first_load'] = false;
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('    ').convert(json));
    await tmp.rename(file.path);
    return read();
  }

  Map<String, Object?> _readJson() {
    if (!file.existsSync()) return {};
    try {
      final json = jsonDecode(file.readAsStringSync());
      return json is Map<String, Object?> ? {...json} : {};
    } on FormatException {
      return {};
    }
  }

  /// 16 letters/digits without look-alikes (0/O, 1/l/I), easy to type.
  static String generatePassword([Random? random]) {
    const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = random ?? Random.secure();
    return List.generate(16, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
