import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'desktop_controller.dart';
import 'home_page.dart';
import 'l10n/app_localizations.dart';

class ObsPadDesktopApp extends StatelessWidget {
  const ObsPadDesktopApp({required this.controller, this.locale, super.key});

  final DesktopController controller;

  /// null = follow the computer language.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      colorSchemeSeed: const Color(0xFF5B4BDB),
      brightness: brightness,
    );
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(controller: controller),
    );
  }
}
