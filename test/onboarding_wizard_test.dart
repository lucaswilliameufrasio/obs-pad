import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_pad/presentation/providers.dart';

import 'fakes/fake_obs_repository.dart';
import 'helpers.dart';

Future<void> goToTestStep(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.byKey(const Key('btn-next')));
    await tester.pumpAndSettle();
  }
  expect(find.text('Passo 4 de 4'), findsOneWidget);
}

Future<void> fillAndTest(
  WidgetTester tester, {
  String host = '192.168.0.15',
  String password = 'segredo',
}) async {
  await tester.enterText(find.byKey(const Key('field-host')), host);
  await tester.enterText(find.byKey(const Key('field-password')), password);
  await tester.tap(find.byKey(const Key('btn-test')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch opens the 4-step guide', (tester) async {
    await pumpObsPad(tester);

    expect(find.text('Passo 1 de 4'), findsOneWidget);
    expect(find.text('Abra o OBS no computador'), findsOneWidget);
    expect(find.textContaining('versão 28'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-next')));
    await tester.pumpAndSettle();
    expect(find.text('Ligue o controle remoto do OBS'), findsOneWidget);
    expect(find.text('No OBS, clique no menu Ferramentas'), findsOneWidget);
    expect(find.text('Deixe a porta 4455 e clique em OK'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-next')));
    await tester.pumpAndSettle();
    expect(find.text('Mesmo Wi-Fi'), findsOneWidget);
    expect(find.textContaining('ipconfig'), findsOneWidget);
    expect(find.textContaining('Ajustes do Sistema > Rede'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-next')));
    await tester.pumpAndSettle();
    expect(find.text('Testar conexão'), findsWidgets);
    expect(find.byKey(const Key('btn-next')), findsNothing);
  });

  testWidgets('back button returns to the previous step', (tester) async {
    await pumpObsPad(tester);
    await tester.tap(find.byKey(const Key('btn-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Passo 1 de 4'), findsOneWidget);
  });

  testWidgets('invalid IP is caught before testing', (tester) async {
    final app = await pumpObsPad(tester);
    await goToTestStep(tester);

    await fillAndTest(tester, host: 'ws://192.168.0.15');
    expect(find.text('Digite só o IP, sem ws://'), findsOneWidget);

    await fillAndTest(tester, host: '192.168.0.15:4455');
    expect(
      find.text('Coloque a porta no campo Porta, não junto do IP'),
      findsOneWidget,
    );
    expect(app.repository.lastTestedConfig, isNull);
  });

  testWidgets('wrong password shows a human message', (tester) async {
    final repo = FakeObsRepository(
      testResult: const ObsFailure(ObsFailureKind.wrongPassword),
    );
    await pumpObsPad(tester, repository: repo);
    await goToTestStep(tester);
    await fillAndTest(tester);

    expect(find.byKey(const Key('test-failure')), findsOneWidget);
    expect(find.text('Senha errada'), findsOneWidget);
    expect(find.textContaining('Mostrar informações de conexão'), findsWidgets);
    expect(find.byKey(const Key('btn-save')), findsNothing);
  });

  testWidgets('timeout explains IP and Windows firewall', (tester) async {
    final repo = FakeObsRepository(
      testResult: const ObsFailure(ObsFailureKind.timeout),
    );
    await pumpObsPad(tester, repository: repo);
    await goToTestStep(tester);
    await fillAndTest(tester);

    expect(find.text('Não consegui chegar ao computador'), findsOneWidget);
    expect(find.textContaining('porta 4455'), findsWidgets);
    expect(
      find.text('Como liberar o OBS no Firewall do Windows'),
      findsOneWidget,
    );
  });

  testWidgets('server off is reported as OBS not answering', (tester) async {
    final repo = FakeObsRepository(
      testResult: const ObsFailure(ObsFailureKind.serverOff),
    );
    await pumpObsPad(tester, repository: repo);
    await goToTestStep(tester);
    await fillAndTest(tester);

    expect(find.text('O OBS não respondeu'), findsOneWidget);
  });

  testWidgets('success saves the profile and opens the app', (tester) async {
    final app = await pumpObsPad(tester);
    await goToTestStep(tester);
    await fillAndTest(tester);

    expect(app.repository.lastTestedConfig?.host, '192.168.0.15');
    expect(app.repository.lastTestedConfig?.port, 4455);
    expect(find.text('Tudo certo! Conectado ao OBS 31.0.0.'), findsOneWidget);
    expect(find.text('Dica sobre sons'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();

    final profiles = app.container.read(profilesProvider);
    expect(profiles.profiles, hasLength(1));
    expect(profiles.active?.host, '192.168.0.15');
    expect(app.secrets.values.values, contains('segredo'));
    expect(app.container.read(settingsProvider).onboardingDone, isTrue);
    expect(app.repository.calls, contains('connect 192.168.0.15'));
    // Home with the scene switcher.
    expect(find.text('Botões'), findsOneWidget);
    expect(find.text('Jogo'), findsOneWidget);
  });

  testWidgets('tapping a scene switches it in OBS', (tester) async {
    final app = await pumpObsPad(tester);
    await goToTestStep(tester);
    await fillAndTest(tester);
    await tester.tap(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jogo'));
    await tester.pumpAndSettle();
    expect(app.repository.calls, contains('scene Jogo'));
    expect(app.repository.currentScene, 'Jogo');
  });
}
