import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import '../../l10n/app_localizations.dart';
import '../providers.dart';
import 'qr_scanner_page.dart';

/// OBS Pad Desktop on the OBS computer, seen from the phone.
abstract interface class ComputerHelper {
  Future<({String folder, List<SoundFile> sounds})> listSounds();
  Future<SoundFile> uploadSound(String fileName, List<int> bytes);
}

class _ClientHelper implements ComputerHelper {
  _ClientHelper(this._client);

  final CompanionClient _client;

  @override
  Future<({String folder, List<SoundFile> sounds})> listSounds() =>
      _client.listSounds();

  @override
  Future<SoundFile> uploadSound(String fileName, List<int> bytes) =>
      _client.uploadSound(fileName, bytes);
}

/// The helper on the active computer, or null when it is not running there
/// (the app works without it).
final computerHelperProvider = FutureProvider.autoDispose<ComputerHelper?>((
  ref,
) async {
  final profiles = ref.watch(profilesProvider);
  final profile = profiles.active;
  if (profile == null) return null;
  final password = await ref
      .read(profilesProvider.notifier)
      .passwordOf(profile.id);
  final client = CompanionClient(host: profile.host, secret: password);
  ref.onDispose(client.close);
  try {
    await client.info();
    return _ClientHelper(client);
  } on CompanionException {
    return null;
  }
});

/// Finds computers running OBS Pad Desktop (UDP broadcast).
final computerFinderProvider =
    Provider<Future<List<DiscoveredComputer>> Function()>(
      (ref) => discoverComputers,
    );

typedef PickedSound = ({String name, List<int> bytes});

/// Lets the user pick an audio file on the phone.
final soundFilePickerProvider = Provider<Future<PickedSound?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(type: FileType.audio);
    if (files.isEmpty) return null;
    final file = files.first;
    return (name: file.name, bytes: await file.readAsBytes());
  },
);

/// Opens the camera and returns the text of the first QR code read.
final qrScannerProvider = Provider<Future<String?> Function(BuildContext)>(
  (ref) =>
      (context) => Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage())),
);

/// Human text for OBS Pad Desktop errors.
String describeCompanionError(AppLocalizations l, Object error) {
  if (error is! CompanionException) return l.companionErrServer;
  return switch (error.kind) {
    CompanionErrorKind.unreachable => l.companionErrUnreachable,
    CompanionErrorKind.unauthorized => l.companionErrUnauthorized,
    CompanionErrorKind.clockSkew => l.companionErrClock,
    CompanionErrorKind.notReady => l.companionErrNotReady,
    CompanionErrorKind.tooLarge => l.companionErrTooLarge,
    CompanionErrorKind.badFile => l.companionErrBadFile,
    CompanionErrorKind.server => l.companionErrServer,
  };
}
