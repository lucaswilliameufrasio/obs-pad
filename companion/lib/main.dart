import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import 'app.dart';
import 'desktop_controller.dart';
import 'system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = DesktopController(
    system: RealDesktopSystem(),
    locateSettings: ObsSettingsFile.locate,
  );
  unawaited(controller.start());
  runApp(ObsPadDesktopApp(controller: controller));
}
