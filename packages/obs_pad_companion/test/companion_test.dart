import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:obs_pad_companion/obs_pad_companion.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('signature', () {
    String sign({
      String secret = 'senha',
      String method = 'POST',
      String path = '/v1/sounds',
      int time = 1000,
      List<int> body = const [1, 2, 3],
    }) => signRequest(
      secret: secret,
      method: method,
      path: path,
      timestampSeconds: time,
      body: body,
    );

    test('same request, same signature', () => expect(sign(), sign()));

    test('any change breaks it', () {
      final base = sign();
      expect(sign(secret: 'outra'), isNot(base));
      expect(sign(method: 'GET'), isNot(base));
      expect(sign(path: '/v1/other'), isNot(base));
      expect(sign(time: 1001), isNot(base));
      expect(sign(body: [1, 2, 4]), isNot(base));
    });

    test('constant-time compare', () {
      expect(signaturesMatch('abc', 'abc'), isTrue);
      expect(signaturesMatch('abc', 'abd'), isFalse);
      expect(signaturesMatch('abc', 'ab'), isFalse);
    });
  });

  group('safe sound file names', () {
    test('keeps normal names', () {
      expect(safeSoundFileName('Aplausos.mp3'), 'Aplausos.mp3');
      expect(safeSoundFileName('buzina final.WAV'), 'buzina final.wav');
    });

    test('drops folders, including path traversal', () {
      expect(safeSoundFileName('../../etc/evil.mp3'), 'evil.mp3');
      expect(safeSoundFileName(r'C:\Users\x\Música\som.ogg'), 'som.ogg');
      expect(safeSoundFileName('/tmp/.hidden.mp3'), 'hidden.mp3');
    });

    test('refuses what is not a sound', () {
      expect(safeSoundFileName('virus.exe'), isNull);
      expect(safeSoundFileName('script.mp3.bat'), isNull);
      expect(safeSoundFileName('semextensao'), isNull);
    });

    test('cleans reserved characters and Windows device names', () {
      expect(safeSoundFileName('a<b>c:d|e?.mp3'), 'abcde.mp3');
      expect(safeSoundFileName('CON.wav'), 'CON_.wav');
      expect(safeSoundFileName('.mp3'), isNull, reason: 'a dotfile');
    });
  });

  group('QR code links', () {
    test("OBS's own QR (obsws://)", () {
      final link = ConnectionLink.tryParse('obsws://192.168.0.15:4455/s3nh4')!;
      expect(link.host, '192.168.0.15');
      expect(link.port, 4455);
      expect(link.password, 's3nh4');
      expect(link.name, isNull);
    });

    test('obsws without password', () {
      final link = ConnectionLink.tryParse('obsws://10.0.0.2:4460')!;
      expect(link.port, 4460);
      expect(link.password, '');
    });

    test('OBS Pad Desktop QR round-trips, with odd passwords', () {
      const original = ConnectionLink(
        host: '192.168.1.20',
        port: 4455,
        password: 'a&b=c/d?e#f',
        name: 'PC da Ana',
      );
      final parsed = ConnectionLink.tryParse(original.toObsPadUri())!;
      expect(parsed.host, original.host);
      expect(parsed.password, original.password);
      expect(parsed.name, 'PC da Ana');
    });

    test('anything else is not a connection', () {
      expect(ConnectionLink.tryParse('https://obsproject.com'), isNull);
      expect(ConnectionLink.tryParse('texto qualquer'), isNull);
      expect(ConnectionLink.tryParse('obspad://connect?port=1'), isNull);
    });
  });

  group('OBS settings file', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('obs'));
    tearDown(() => dir.delete(recursive: true));

    test('where OBS keeps its settings on each system', () {
      expect(
        ObsSettingsFile.candidateDirs(
          operatingSystem: 'windows',
          environment: {'APPDATA': r'C:\Users\ana\AppData\Roaming'},
        ).first,
        r'C:\Users\ana\AppData\Roaming\obs-studio',
      );
      expect(
        ObsSettingsFile.candidateDirs(
          operatingSystem: 'macos',
          environment: {'HOME': '/Users/ana'},
        ).first,
        '/Users/ana/Library/Application Support/obs-studio',
      );
      final linux = ObsSettingsFile.candidateDirs(
        operatingSystem: 'linux',
        environment: {'HOME': '/home/ana'},
      );
      expect(linux, contains('/home/ana/.config/obs-studio'));
      expect(
        linux,
        contains('/home/ana/.var/app/com.obsproject.Studio/config/obs-studio'),
      );
    });

    test('locate finds the existing folder only', () {
      final env = {'HOME': dir.path};
      expect(
        ObsSettingsFile.locate(operatingSystem: 'linux', environment: env),
        isNull,
      );
      Directory(p.join(dir.path, '.config', 'obs-studio'))
          .createSync(recursive: true);
      final found = ObsSettingsFile.locate(
        operatingSystem: 'linux',
        environment: env,
      )!;
      expect(
        found.file.path,
        p.join(
          dir.path,
          '.config/obs-studio/plugin_config/obs-websocket/config.json',
        ),
      );
    });

    test('no file yet: OBS defaults (server off)', () {
      final settings = ObsSettingsFile.inDir(dir.path).read();
      expect(settings.enabled, isFalse);
      expect(settings.port, 4455);
      expect(settings.readyForPhone, isFalse);
    });

    test('enabling creates a password and keeps other settings', () async {
      final file = ObsSettingsFile.inDir(dir.path);
      await file.file.parent.create(recursive: true);
      await file.file.writeAsString(
        jsonEncode({
          'server_enabled': false,
          'server_port': 4460,
          'alerts_enabled': true,
        }),
      );

      final settings = await file.enableForPhone();
      expect(settings.enabled, isTrue);
      expect(settings.authRequired, isTrue);
      expect(settings.port, 4460);
      expect(settings.password, hasLength(16));
      expect(settings.readyForPhone, isTrue);
      final json = jsonDecode(await file.file.readAsString()) as Map;
      expect(json['alerts_enabled'], isTrue);
    });

    test('enabling keeps an existing password', () async {
      final file = ObsSettingsFile.inDir(dir.path);
      await file.file.parent.create(recursive: true);
      await file.file.writeAsString(
        jsonEncode({'server_password': 'minha-senha', 'auth_required': false}),
      );
      final settings = await file.enableForPhone();
      expect(settings.password, 'minha-senha');
      expect(settings.authRequired, isTrue);
    });

    test('generated passwords avoid look-alike characters', () {
      final password = ObsSettingsFile.generatePassword(Random(1));
      expect(password, hasLength(16));
      expect(password, isNot(matches(RegExp('[0O1lI]'))));
    });
  });

  group('server and client', () {
    late Directory sounds;
    late CompanionServer server;
    late List<CompanionActivity> activity;
    String? secret = 'senha-do-obs';

    CompanionClient client({String? password, DateTime Function()? clock}) =>
        CompanionClient(
          host: '127.0.0.1',
          port: server.httpPort,
          secret: password ?? 'senha-do-obs',
          clock: clock,
        );

    setUp(() async {
      secret = 'senha-do-obs';
      sounds = await Directory.systemTemp.createTemp('sons');
      activity = [];
      server = CompanionServer(
        secret: () => secret,
        soundsDir: Directory(p.join(sounds.path, 'OBS Pad', 'Sons')),
        announcement: () => const CompanionAnnouncement(
          name: 'PC da live',
          obsPort: 4455,
          companionPort: 0,
          version: 'test',
        ),
        port: 0,
        maxUploadBytes: 1024 * 1024,
        onActivity: activity.add,
      );
      await server.start();
    });

    tearDown(() async {
      await server.stop();
      await sounds.delete(recursive: true);
    });

    test('info does not need the password', () async {
      final result = await client(password: 'errada').info();
      expect(result.info.name, 'PC da live');
      expect(result.ready, isTrue);
    });

    test('upload, then list', () async {
      final c = client();
      final saved = await c.uploadSound('Aplausos.mp3', [1, 2, 3, 4]);
      expect(saved.name, 'Aplausos.mp3');
      expect(p.isAbsolute(saved.path), isTrue);
      expect(await File(saved.path).readAsBytes(), [1, 2, 3, 4]);

      final listed = await c.listSounds();
      expect(listed.folder, endsWith(p.join('OBS Pad', 'Sons')));
      expect(listed.sounds.single.path, saved.path);
      expect(
        activity.map((a) => a.kind),
        containsAllInOrder([
          CompanionActivityKind.uploaded,
          CompanionActivityKind.listed,
        ]),
      );
    });

    test(
      'same file twice is reused; a different one is not overwritten',
      () async {
        final c = client();
        final first = await c.uploadSound('som.wav', [1, 2, 3]);
        final again = await c.uploadSound('som.wav', [1, 2, 3]);
        final other = await c.uploadSound('som.wav', [9, 9]);
        expect(again.path, first.path);
        expect(other.name, 'som (2).wav');
        expect(await File(first.path).readAsBytes(), [1, 2, 3]);
      },
    );

    test('path traversal stays inside the sounds folder', () async {
      final saved = await client().uploadSound('../../fora.mp3', [1]);
      expect(p.dirname(saved.path), server.soundsDir.absolute.path);
    });

    test('wrong OBS password is refused', () async {
      await expectLater(
        client(password: 'errada').listSounds(),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.unauthorized,
          ),
        ),
      );
      expect(activity.last.kind, CompanionActivityKind.rejected);
    });

    test('OBS without a password: not ready', () async {
      secret = null;
      expect((await client().info()).ready, isFalse);
      await expectLater(
        client().listSounds(),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.notReady,
          ),
        ),
      );
    });

    test('phone clock far off is reported as such', () async {
      final late = client(
        clock: () => DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await expectLater(
        late.listSounds(),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.clockSkew,
          ),
        ),
      );
    });

    test('not a sound file', () async {
      await expectLater(
        client().uploadSound('virus.exe', [1]),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.badFile,
          ),
        ),
      );
    });

    test('server refuses a bad file name even from a custom client', () async {
      // Signed correctly, but bypassing the client-side check.
      final http = HttpClient();
      addTearDown(http.close);
      final request = await http.post(
        '127.0.0.1',
        server.httpPort,
        '/v1/sounds',
      );
      final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      request.headers
        ..set(fileNameHeader, 'virus.exe')
        ..set(timeHeader, '$time')
        ..set(
          signatureHeader,
          signRequest(
            secret: 'senha-do-obs',
            method: 'POST',
            path: '/v1/sounds',
            timestampSeconds: time,
            body: [1],
          ),
        );
      request.add([1]);
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, 400);
      expect(server.soundsDir.existsSync(), isFalse);
    });

    test('too big', () async {
      await expectLater(
        client().uploadSound('grande.mp3', List.filled(1024 * 1024 + 1, 0)),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.tooLarge,
          ),
        ),
      );
    });

    test('nobody there: unreachable', () async {
      final port = server.httpPort;
      await server.stop();
      final c = CompanionClient(host: '127.0.0.1', port: port, secret: 'x');
      await expectLater(
        c.info(),
        throwsA(
          isA<CompanionException>().having(
            (e) => e.kind,
            'kind',
            CompanionErrorKind.unreachable,
          ),
        ),
      );
    });

    test('discovery answers with the computer name', () async {
      final found = await discoverComputers(
        port: server.discoveryPort,
        broadcast: false,
        extraTargets: [InternetAddress.loopbackIPv4],
        timeout: const Duration(milliseconds: 600),
      );
      expect(found.single.address, '127.0.0.1');
      expect(found.single.announcement.name, 'PC da live');
      expect(activity.first.kind, CompanionActivityKind.discovered);
    });
  });
}
