import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';

/// Localizations outside the widget tree (e.g. default names created by
/// notifiers), following the language chosen in settings.
AppLocalizations l10nOf(Ref ref) {
  final code =
      ref.read(settingsProvider).localeCode ??
      PlatformDispatcher.instance.locale.languageCode;
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == code,
  );
  return lookupAppLocalizations(Locale(supported ? code : 'en'));
}
