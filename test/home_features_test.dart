import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/domain/obs_events.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_pad/domain/sound/sound_models.dart';

import 'fakes/fake_obs_repository.dart';
import 'helpers.dart';

/// Already configured app: skips the guide and connects to the fake OBS.
Map<String, Object> configured({
  List<SoundPad> pads = const [],
  Map<String, Object> extra = const {},
}) => {
  ...extra,
  'onboarding_done': true,
  'connection_profiles_v1': jsonEncode([
    {'id': 'pc', 'name': 'PC da live', 'host': '192.168.0.15', 'port': 4455},
  ]),
  'active_profile_id': 'pc',
  if (pads.isNotEmpty)
    'soundboard_v1': jsonEncode({
      'items': [
        {
          'id': 'main',
          'name': 'Principal',
          'pages': [
            {
              'id': 'p1',
              'name': 'Sons',
              'pads': pads.map((p) => p.toJson()).toList(),
            },
          ],
        },
      ],
      'active': 'main',
    }),
};

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pad button starts the live and lights up from OBS events', (
    tester,
  ) async {
    final app = await pumpObsPad(tester, prefs: configured());
    expect(find.text('PC da live'), findsOneWidget);
    expect(app.repository.calls, contains('connect 192.168.0.15'));

    await tester.tap(find.text('Iniciar/parar live'));
    await tester.pumpAndSettle();
    expect(app.repository.calls, contains('toggleStream'));
    expect(find.text('AO VIVO'), findsNothing);

    // OBS confirms the live started: the button shows it.
    app.repository.emit(
      const StreamStateChanged(
        active: true,
        state: 'OBS_WEBSOCKET_OUTPUT_STARTED',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AO VIVO'), findsOneWidget);

    // Stopping the live asks first.
    app.repository.calls.clear();
    await tester.tap(find.text('Iniciar/parar live'));
    await tester.pumpAndSettle();
    expect(find.text('Parar a live?'), findsOneWidget);
    expect(app.repository.calls, isNot(contains('toggleStream')));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(app.repository.calls, contains('toggleStream'));
  });

  testWidgets('scene strip follows the scene changed in OBS', (tester) async {
    final app = await pumpObsPad(tester, prefs: configured());
    app.repository.emit(const CurrentSceneChanged('Intervalo'));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('scene-Intervalo')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('button for a missing scene shows a human error', (tester) async {
    final app = await pumpObsPad(tester, prefs: configured());
    // Create a scene button through the editor.
    await tester.tap(find.byKey(const Key('btn-edit-pad')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar botão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cena').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-edit-pad')));
    await tester.pumpAndSettle();

    // The scene is deleted in OBS.
    app.repository.scenes = app.repository.scenes
        .where((s) => s.name != 'Jogo')
        .toList();
    await tester.tap(
      find.descendant(of: find.byType(GridView), matching: find.text('Jogo')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não encontrei "Jogo" no OBS. Pode ter sido renomeado ou apagado no OBS. Edite o botão e escolha de novo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mixer subscribes to volume meters only while open', (
    tester,
  ) async {
    final app = await pumpObsPad(tester, prefs: configured());
    expect(app.repository.calls, isNot(contains('meters true')));

    await openTab(tester, 'Mixer');
    expect(app.repository.calls, contains('meters true'));
    expect(find.text('Mic'), findsOneWidget);

    app.repository.emit(const InputVolumeMeters({'Mic': 0.5}));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mute-Mic')));
    await tester.pumpAndSettle();
    expect(app.repository.calls, contains('mute Mic true'));

    app.repository.calls.clear();
    await openTab(tester, 'Botões');
    expect(app.repository.calls, contains('meters false'));
  });

  testWidgets('sound pad plays, ducks the music and restores it', (
    tester,
  ) async {
    const pad = SoundPad(
      id: 'buzina',
      label: 'Buzina',
      inputName: 'Buzina',
      emoji: '📢',
      ducking: DuckingConfig(inputName: 'Música', reductionDb: 20),
    );
    final app = await pumpObsPad(tester, prefs: configured(pads: [pad]));
    await openTab(tester, 'Sons');

    await tester.tap(find.text('Buzina'));
    await tester.pumpAndSettle();
    expect(app.repository.calls, contains('media Buzina restart'));
    // 0.5 * -20 dB = 0.05
    expect(app.repository.calls, contains('volume Música 0.05'));

    app.repository.emit(const MediaPlaybackStarted('Buzina'));
    await tester.pumpAndSettle();
    expect(find.text('TOCANDO'), findsOneWidget);

    app.repository.emit(const MediaPlaybackEnded('Buzina'));
    await tester.pumpAndSettle();
    expect(find.text('TOCANDO'), findsNothing);
    expect(app.repository.volumes['Música'], 0.5);
  });

  testWidgets('volume left lowered by a closed app is restored on connect', (
    tester,
  ) async {
    final repo = FakeObsRepository()..volumes['Música'] = 0.05;
    final app = await pumpObsPad(
      tester,
      repository: repo,
      prefs: configured(
        extra: {
          'ducking_originals_v1': jsonEncode({'Música': 0.5}),
        },
      ),
    );
    expect(app.repository.volumes['Música'], 0.5);
    expect(app.repository.calls, contains('volume Música 0.50'));
  });

  testWidgets('sound outside the scene on air: explains and fixes it', (
    tester,
  ) async {
    final repo = FakeObsRepository()..playsOnRestart = false;
    await pumpObsPad(
      tester,
      repository: repo,
      prefs: configured(
        pads: const [SoundPad(id: 'b', label: 'Buzina', inputName: 'Buzina')],
      ),
    );
    await openTab(tester, 'Sons');
    await tester.tap(find.text('Buzina'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('não está na cena que está no ar'),
      findsOneWidget,
    );

    // One tap puts it in every scene and plays it again.
    repo
      ..playsOnRestart = true
      ..calls.clear();
    await tester.tap(find.text('Pôr em todas as cenas'));
    await tester.pumpAndSettle();
    expect(repo.calls, [
      'addToScenes Buzina Começando,Jogo,Intervalo',
      'media Buzina restart',
    ]);
    expect(
      find.textContaining('não está na cena que está no ar'),
      findsNothing,
    );
  });

  testWidgets('panic button stops every sound', (tester) async {
    const pads = [
      SoundPad(id: 'a', label: 'A', inputName: 'Som A'),
      SoundPad(id: 'b', label: 'B', inputName: 'Som B'),
    ];
    final app = await pumpObsPad(tester, prefs: configured(pads: pads));
    await openTab(tester, 'Sons');
    await tester.tap(find.byKey(const Key('btn-panic')));
    await tester.pumpAndSettle();
    expect(
      app.repository.calls,
      containsAll(['media Som A stop', 'media Som B stop']),
    );
    expect(find.text('Todos os sons foram parados.'), findsOneWidget);
  });

  testWidgets('missing media input gets a sound-specific message', (
    tester,
  ) async {
    final repo = _MissingMediaRepository();
    await pumpObsPad(
      tester,
      repository: repo,
      prefs: configured(
        pads: const [SoundPad(id: 'x', label: 'Sumiu', inputName: 'Som X')],
      ),
    );
    await openTab(tester, 'Sons');
    await tester.tap(find.text('Sumiu'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A fonte de som "Som X" não existe no OBS'),
      findsOneWidget,
    );
  });

  testWidgets('"Adicionar som" creates the media source in OBS', (
    tester,
  ) async {
    final app = await pumpObsPad(tester, prefs: configured());
    await openTab(tester, 'Sons');
    await tester.tap(find.text('Adicionar som'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('field-sound-label')),
      'Aplausos',
    );
    await tester.enterText(
      find.byKey(const Key('field-sound-path')),
      r'C:\Sons\aplausos.mp3',
    );
    await tester.tap(find.byKey(const Key('btn-add-sound')));
    await tester.pumpAndSettle();

    expect(
      app.repository.calls,
      contains(r'setupMedia Som - Aplausos C:\Sons\aplausos.mp3'),
    );
    expect(find.text('Aplausos'), findsOneWidget);
  });
}

class _MissingMediaRepository extends FakeObsRepository {
  @override
  Future<void> triggerMediaAction(String inputName, _) async =>
      throw ObsFailure(ObsFailureKind.resourceNotFound, resource: inputName);
}
