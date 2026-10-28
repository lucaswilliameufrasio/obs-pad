import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/app.dart';
import 'package:obs_pad/data/storage/profiles_store.dart';
import 'package:obs_pad/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_obs_repository.dart';

class TestApp {
  TestApp(this.repository, this.secrets, this.container);

  final FakeObsRepository repository;
  final MemorySecretStore secrets;
  final ProviderContainer container;
}

/// Pumps the whole app in Portuguese on a tall screen with a fake OBS.
Future<TestApp> pumpObsPad(
  WidgetTester tester, {
  FakeObsRepository? repository,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'locale': 'pt', ...prefs});
  final sharedPrefs = await SharedPreferences.getInstance();
  final repo = repository ?? FakeObsRepository();
  final secrets = MemorySecretStore();
  // Owned by the widget tree, so periodic timers (metrics polling) are
  // cancelled when the test tears the tree down.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        secretStoreProvider.overrideWithValue(secrets),
        obsRepositoryProvider.overrideWithValue(repo),
      ],
      child: const ObsPadApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ObsPadApp)),
  );
  return TestApp(repo, secrets, container);
}
