import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/presentation/companion/computer_helper.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import 'helpers.dart';
import 'onboarding_wizard_test.dart' show goToTestStep;

class FakeHelper implements ComputerHelper {
  final uploads = <String>[];
  Object? uploadError;
  List<SoundFile> folder = const [];

  @override
  Future<({String folder, List<SoundFile> sounds})> listSounds() async =>
      (folder: r'C:\Users\Ana\OBS Pad\Sons', sounds: folder);

  @override
  Future<SoundFile> uploadSound(String fileName, List<int> bytes) async {
    if (uploadError != null) throw uploadError!;
    uploads.add('$fileName ${bytes.length}');
    return SoundFile(
      name: fileName,
      path: r'C:\Users\Ana\OBS Pad\Sons\' + fileName,
      sizeBytes: bytes.length,
    );
  }
}

Map<String, Object> get configured => {
  'onboarding_done': true,
  'connection_profiles_v1': jsonEncode([
    {'id': 'pc', 'name': 'PC da live', 'host': '192.168.0.15', 'port': 4455},
  ]),
  'active_profile_id': 'pc',
};

Future<void> openAddSound(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Sons'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Adicionar som'));
  await tester.pumpAndSettle();
}

void main() {
  group('connection form', () {
    testWidgets('"Procurar na rede" fills the computer found', (tester) async {
      await pumpObsPad(
        tester,
        overrides: [
          computerFinderProvider.overrideWithValue(
            () async => const [
              DiscoveredComputer(
                '192.168.0.42',
                CompanionAnnouncement(
                  name: 'PC do Estúdio',
                  obsPort: 4460,
                  companionPort: 4457,
                  version: '1.0.0',
                ),
              ),
            ],
          ),
        ],
      );
      await goToTestStep(tester);
      await tester.tap(find.byKey(const Key('btn-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PC do Estúdio'));
      await tester.pumpAndSettle();

      String text(String key) =>
          tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
      expect(text('field-host'), '192.168.0.42');
      expect(text('field-port'), '4460');
      expect(text('field-name'), 'PC do Estúdio');
    });

    testWidgets('nothing found explains why', (tester) async {
      await pumpObsPad(
        tester,
        overrides: [
          computerFinderProvider.overrideWithValue(() async => const []),
        ],
      );
      await goToTestStep(tester);
      await tester.tap(find.byKey(const Key('btn-find')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('find-none')), findsOneWidget);
    });

    testWidgets('QR code fills everything and tests right away', (
      tester,
    ) async {
      final app = await pumpObsPad(
        tester,
        overrides: [
          qrScannerProvider.overrideWithValue(
            (_) async => const ConnectionLink(
              host: '192.168.0.20',
              port: 4455,
              password: 'a&b',
              name: 'PC da Ana',
            ).toObsPadUri(),
          ),
        ],
      );
      await goToTestStep(tester);
      await tester.tap(find.byKey(const Key('btn-read-qr')));
      await tester.pumpAndSettle();
      expect(app.repository.lastTestedConfig?.host, '192.168.0.20');
      expect(app.repository.lastTestedConfig?.password, 'a&b');
      expect(find.byKey(const Key('test-success')), findsOneWidget);
    });

    testWidgets("OBS's own QR code works too", (tester) async {
      final app = await pumpObsPad(
        tester,
        overrides: [
          qrScannerProvider.overrideWithValue(
            (_) async => 'obsws://10.0.0.5:4455/s3nh4',
          ),
        ],
      );
      await goToTestStep(tester);
      await tester.tap(find.byKey(const Key('btn-read-qr')));
      await tester.pumpAndSettle();
      expect(app.repository.lastTestedConfig?.host, '10.0.0.5');
      expect(app.repository.lastTestedConfig?.password, 's3nh4');
    });

    testWidgets('a QR code that is not a connection', (tester) async {
      await pumpObsPad(
        tester,
        overrides: [
          qrScannerProvider.overrideWithValue(
            (_) async => 'https://example.com',
          ),
        ],
      );
      await goToTestStep(tester);
      await tester.tap(find.byKey(const Key('btn-read-qr')));
      await tester.pumpAndSettle();
      expect(
        find.text('Esse QR code não é de conexão do OBS.'),
        findsOneWidget,
      );
    });
  });

  group('add sound with OBS Pad Desktop', () {
    testWidgets('without it: just a tip, typing the path still works', (
      tester,
    ) async {
      await pumpObsPad(
        tester,
        prefs: configured,
        overrides: [computerHelperProvider.overrideWith((ref) async => null)],
      );
      await openAddSound(tester);
      expect(find.byKey(const Key('companion-tip')), findsOneWidget);
      expect(find.byKey(const Key('btn-send-from-phone')), findsNothing);
    });

    testWidgets('send a sound from the phone and create it in OBS', (
      tester,
    ) async {
      final helper = FakeHelper();
      final app = await pumpObsPad(
        tester,
        prefs: configured,
        overrides: [
          computerHelperProvider.overrideWith((ref) async => helper),
          soundFilePickerProvider.overrideWithValue(
            () async => (name: 'Aplausos.mp3', bytes: List.filled(10, 1)),
          ),
        ],
      );
      await openAddSound(tester);
      await tester.tap(find.byKey(const Key('btn-send-from-phone')));
      await tester.pumpAndSettle();
      expect(helper.uploads, ['Aplausos.mp3 10']);

      String text(String key) =>
          tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
      expect(
        text('field-sound-path'),
        r'C:\Users\Ana\OBS Pad\Sons\Aplausos.mp3',
      );
      expect(text('field-sound-label'), 'Aplausos');

      await tester.tap(find.byKey(const Key('btn-add-sound')));
      await tester.pumpAndSettle();
      expect(
        app.repository.calls,
        contains(
          r'setupMedia Som - Aplausos C:\Users\Ana\OBS Pad\Sons\Aplausos.mp3',
        ),
      );
    });

    testWidgets('pick a sound already in the computer folder', (tester) async {
      final helper = FakeHelper()
        ..folder = const [
          SoundFile(
            name: 'Buzina.wav',
            path: '/home/ana/OBS Pad/Sons/Buzina.wav',
            sizeBytes: 2048,
          ),
        ];
      await pumpObsPad(
        tester,
        prefs: configured,
        overrides: [computerHelperProvider.overrideWith((ref) async => helper)],
      );
      await openAddSound(tester);
      await tester.tap(find.byKey(const Key('btn-pick-from-computer')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buzina.wav'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('field-sound-path')))
            .controller!
            .text,
        '/home/ana/OBS Pad/Sons/Buzina.wav',
      );
    });

    testWidgets('wrong password on the phone is explained', (tester) async {
      final helper = FakeHelper()
        ..uploadError = const CompanionException(
          CompanionErrorKind.unauthorized,
        );
      await pumpObsPad(
        tester,
        prefs: configured,
        overrides: [
          computerHelperProvider.overrideWith((ref) async => helper),
          soundFilePickerProvider.overrideWithValue(
            () async => (name: 'x.mp3', bytes: [1]),
          ),
        ],
      );
      await openAddSound(tester);
      await tester.tap(find.byKey(const Key('btn-send-from-phone')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('A senha do OBS neste celular é diferente'),
        findsOneWidget,
      );
    });
  });
}
