import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.keepScreenOn = true,
    this.haptics = true,
    this.onboardingDone = false,
    this.chartWindowMinutes = 3,
  });

  final ThemeMode themeMode;

  /// null = follow the phone language.
  final String? localeCode;
  final bool keepScreenOn;
  final bool haptics;
  final bool onboardingDone;

  /// 2..5 minutes of history in the dashboard charts.
  final int chartWindowMinutes;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? localeCode,
    bool? keepScreenOn,
    bool? haptics,
    bool? onboardingDone,
    int? chartWindowMinutes,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    localeCode: localeCode != null ? localeCode() : this.localeCode,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    haptics: haptics ?? this.haptics,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    chartWindowMinutes: chartWindowMinutes ?? this.chartWindowMinutes,
  );
}

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  AppSettings load() => AppSettings(
    themeMode:
        ThemeMode.values.elementAtOrNull(_prefs.getInt('theme_mode') ?? 0) ??
        ThemeMode.system,
    localeCode: _prefs.getString('locale'),
    keepScreenOn: _prefs.getBool('keep_screen_on') ?? true,
    haptics: _prefs.getBool('haptics') ?? true,
    onboardingDone: _prefs.getBool('onboarding_done') ?? false,
    chartWindowMinutes: (_prefs.getInt('chart_window_minutes') ?? 3).clamp(
      2,
      5,
    ),
  );

  Future<void> save(AppSettings s) async {
    await _prefs.setInt('theme_mode', s.themeMode.index);
    if (s.localeCode == null) {
      await _prefs.remove('locale');
    } else {
      await _prefs.setString('locale', s.localeCode!);
    }
    await _prefs.setBool('keep_screen_on', s.keepScreenOn);
    await _prefs.setBool('haptics', s.haptics);
    await _prefs.setBool('onboarding_done', s.onboardingDone);
    await _prefs.setInt('chart_window_minutes', s.chartWindowMinutes);
  }
}
