import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// TCP port of the HTTP API and UDP port of discovery, on the OBS computer.
const int defaultCompanionPort = 4457;

/// Sent by the phone (UDP broadcast) to find computers running the app.
const String discoveryRequest = 'OBSPAD_DISCOVER_V1';

/// API version, part of every path.
const String apiPrefix = '/v1';

const String timeHeader = 'x-obspad-time';
const String signatureHeader = 'x-obspad-signature';
const String fileNameHeader = 'x-obspad-filename';

/// Requests older or newer than this (clock skew) are rejected.
const Duration maxClockSkew = Duration(minutes: 5);

/// Uploads bigger than this are refused (a sound effect, not a movie).
const int maxSoundBytes = 50 * 1024 * 1024;

/// Files OBS's Media Source plays as audio.
const Set<String> soundExtensions = {
  '.mp3',
  '.wav',
  '.ogg',
  '.oga',
  '.opus',
  '.m4a',
  '.aac',
  '.flac',
  '.webm',
  '.mp4',
};

/// What a computer answers to [discoveryRequest].
class CompanionAnnouncement {
  const CompanionAnnouncement({
    required this.name,
    required this.obsPort,
    required this.companionPort,
    required this.version,
    this.obsServerEnabled = true,
  });

  factory CompanionAnnouncement.fromJson(Map<String, Object?> json) =>
      CompanionAnnouncement(
        name: json['name'] as String? ?? '',
        obsPort: (json['obsPort'] as num?)?.toInt() ?? 4455,
        companionPort:
            (json['companionPort'] as num?)?.toInt() ?? defaultCompanionPort,
        version: json['version'] as String? ?? '',
        obsServerEnabled: json['obsServerEnabled'] as bool? ?? true,
      );

  /// Computer name shown on the phone.
  final String name;

  /// Port of the OBS WebSocket server, read from the OBS settings.
  final int obsPort;
  final int companionPort;
  final String version;

  /// False when the OBS WebSocket server is turned off in OBS.
  final bool obsServerEnabled;

  Map<String, Object?> toJson() => {
    'type': 'obspad-announce',
    'name': name,
    'obsPort': obsPort,
    'companionPort': companionPort,
    'version': version,
    'obsServerEnabled': obsServerEnabled,
  };

  static CompanionAnnouncement? tryParse(List<int> datagram) {
    try {
      final json = jsonDecode(utf8.decode(datagram));
      if (json is! Map<String, Object?> || json['type'] != 'obspad-announce') {
        return null;
      }
      return CompanionAnnouncement.fromJson(json);
    } on FormatException {
      return null;
    }
  }
}

/// A sound file in the computer's sounds folder.
class SoundFile {
  const SoundFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  factory SoundFile.fromJson(Map<String, Object?> json) => SoundFile(
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
  );

  final String name;

  /// Absolute path on the computer: what goes into the OBS Media Source.
  final String path;
  final int sizeBytes;

  Map<String, Object?> toJson() => {
    'name': name,
    'path': path,
    'sizeBytes': sizeBytes,
  };
}

/// HMAC-SHA256 of the request, keyed with the OBS WebSocket password.
///
/// Both sides already know that password, so nothing extra has to be paired
/// and the password itself never travels over the network.
String signRequest({
  required String secret,
  required String method,
  required String path,
  required int timestampSeconds,
  required List<int> body,
}) {
  final bodyHash = sha256.convert(body).toString();
  final message =
      '${method.toUpperCase()}\n$path\n$timestampSeconds\n$bodyHash';
  return Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(message)).toString();
}

/// Constant-time comparison, so the signature can't be guessed byte by byte.
bool signaturesMatch(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// A safe file name for the sounds folder, or null if it is not a sound.
///
/// Drops any folder part (no `../`), control and reserved characters, and
/// keeps the extension.
String? safeSoundFileName(String original) {
  // Both separators: the phone may send a Windows or a Unix name.
  final base = original.split(RegExp(r'[\\/]')).last.trim();
  final extension = p.extension(base).toLowerCase();
  if (!soundExtensions.contains(extension)) return null;
  var stem = p
      .basenameWithoutExtension(base)
      .replaceAll(RegExp(r'[\x00-\x1f<>:"|?*]'), '')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  if (stem.length > 80) stem = stem.substring(0, 80).trim();
  if (stem.isEmpty) stem = 'som';
  // Windows reserved device names.
  if (RegExp(
    r'^(con|prn|aux|nul|com\d|lpt\d)$',
    caseSensitive: false,
  ).hasMatch(stem)) {
    stem = '${stem}_';
  }
  return '$stem$extension';
}
