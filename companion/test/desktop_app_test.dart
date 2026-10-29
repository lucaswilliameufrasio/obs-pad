import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';
import 'package:obs_pad_desktop/app.dart';
import 'package:obs_pad_desktop/desktop_controller.dart';
import 'package:obs_pad_desktop/system.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';

class FakeSystem implements DesktopSystem {
  FakeSystem(this.root);

  final Directory root;
  bool obsRunning = false;
  bool windows = false;
  final opened = <String>[];

  @override
  String get computerName => 'PC da live';

  @override
  bool get isWindows => windows;

  @override
  Directory get soundsDir => Directory(p.join(root.path, 'OBS Pad', 'Sons'));

  @override
  Future<bool> isObsRunning() async => obsRunning;

  @override
  Future<List<LanAddress>> lanAddresses() async => const [
    LanAddress('192.168.0.15'),
    LanAddress('100.101.102.103', vpn: true),
  ];

  @override
  Future<void> openFolder(Directory dir) async => opened.add(dir.path);

  @override
  Future<bool> allowThroughFirewall({required int obsPort}) async => true;
}

/// Real IO started from a tap needs fake-time pumps (to run the
/// microtasks) and real time (for the IO itself), alternately.
Future<void> settleRealIo(WidgetTester tester, {bool Function()? until}) async {
  for (var i = 0; i < 50 && !(until?.call() ?? i >= 10); i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  late Directory root;
  late FakeSystem system;

  setUp(() {
    // flutter_test answers every HTTP request with 400; these tests talk to
    // the real server on loopback.
    HttpOverrides.global = null;
    root = Directory.systemTemp.createTempSync('desktop');
    system = FakeSystem(root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  ObsSettingsFile obsDir() =>
      ObsSettingsFile.inDir(p.join(root.path, 'obs-studio'));

  Future<DesktopController> pumpApp(
    WidgetTester tester, {
    ObsSettingsFile? settings,
  }) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = DesktopController(
      system: system,
      locateSettings: () => settings,
      port: 0,
      refreshEvery: const Duration(days: 1),
    );
    await tester.runAsync(controller.start);
    await tester.pumpWidget(
      ObsPadDesktopApp(controller: controller, locale: const Locale('pt')),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
    return controller;
  }

  testWidgets('OBS never opened: explains what to do', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Abra o OBS uma vez'), findsOneWidget);
    expect(find.byKey(const Key('btn-enable')), findsNothing);
  });

  testWidgets('turns on phone control only with OBS closed', (tester) async {
    final settings = obsDir();
    final controller = await pumpApp(tester, settings: settings);
    system.obsRunning = true;
    await tester.runAsync(controller.refresh);
    await tester.pump();

    expect(find.text('Controle pelo celular desligado'), findsOneWidget);
    expect(find.byKey(const Key('needs-closed-obs')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Ligar o controle pelo celular'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);

    // User closes OBS.
    system.obsRunning = false;
    await tester.runAsync(controller.refresh);
    await tester.pump();
    await tester.tap(find.text('Ligar o controle pelo celular'));
    await settleRealIo(
      tester,
      until: () => find.byKey(const Key('enable-done')).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    final written = settings.read();
    expect(written.readyForPhone, isTrue);
    expect(find.byKey(const Key('enable-done')), findsOneWidget);
    expect(
      find.text('Controle pelo celular ligado (porta 4455, com senha)'),
      findsOneWidget,
    );
    expect(find.text('192.168.0.15'), findsOneWidget);
    expect(
      find.text('100.101.102.103 (VPN, funciona fora de casa)'),
      findsOneWidget,
    );

    // The QR code carries what the phone needs.
    await tester.tap(find.byKey(const Key('btn-qr')));
    await tester.pumpAndSettle();
    final qr = tester.widget<QrImageView>(find.byKey(const Key('qr')));
    final link = ConnectionLink.tryParse(
      controller.connectionLink!.toObsPadUri(),
    )!;
    expect(link.host, '192.168.0.15');
    expect(link.password, written.password);
    expect(link.name, 'PC da live');
    expect(qr, isNotNull);
  });

  testWidgets('sounds sent by the phone show up', (tester) async {
    final settings = obsDir();
    settings.file.parent.createSync(recursive: true);
    settings.file.writeAsStringSync(
      jsonEncode({
        'server_enabled': true,
        'auth_required': true,
        'server_password': 'senha',
        'server_port': 4455,
      }),
    );
    final controller = await pumpApp(tester, settings: settings);
    expect(find.text('Nenhum som ainda'), findsOneWidget);

    await tester.runAsync(() async {
      final client = CompanionClient(
        host: '127.0.0.1',
        port: controller.server!.httpPort,
        secret: 'senha',
      );
      await client.uploadSound('Aplausos.mp3', utf8.encode('fake mp3'));
      client.close();
    });
    await settleRealIo(tester, until: () => controller.soundCount == 1);

    expect(find.textContaining('Recebi "Aplausos.mp3"'), findsOneWidget);
    expect(find.text('1 som'), findsOneWidget);

    await tester.tap(find.text('Abrir pasta'));
    expect(system.opened.single, system.soundsDir.path);
  });

  testWidgets('wrong password on the phone is explained', (tester) async {
    final settings = obsDir();
    settings.file.parent.createSync(recursive: true);
    settings.file.writeAsStringSync(
      jsonEncode({'server_enabled': true, 'server_password': 'senha'}),
    );
    final controller = await pumpApp(tester, settings: settings);
    await tester.runAsync(() async {
      final client = CompanionClient(
        host: '127.0.0.1',
        port: controller.server!.httpPort,
        secret: 'errada',
      );
      try {
        await client.listSounds();
      } on CompanionException catch (e) {
        expect(e.kind, CompanionErrorKind.unauthorized);
        // Expected.
      }
      client.close();
    });
    await tester.pumpAndSettle();
    expect(
      find.textContaining('a senha do OBS no celular é diferente'),
      findsOneWidget,
    );
  });

  testWidgets('firewall help only on Windows', (tester) async {
    await pumpApp(tester, settings: obsDir());
    expect(find.text('Firewall do Windows'), findsNothing);
  });
}
