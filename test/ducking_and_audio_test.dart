import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/domain/audio_math.dart';
import 'package:obs_pad/domain/sound/ducking_controller.dart';

void main() {
  group('audio math', () {
    test('dB <-> multiplier', () {
      expect(mulToDb(1), 0);
      expect(mulToDb(0.5), closeTo(-6.02, 0.01));
      expect(mulToDb(0), double.negativeInfinity);
      expect(dbToMul(-20), closeTo(0.1, 0.0001));
      expect(dbToMul(double.negativeInfinity), 0);
    });

    test('fader taper round-trips', () {
      for (final p in [0.0, 0.1, 0.5, 0.9, 1.0]) {
        expect(mulToFader(faderToMul(p)), closeTo(p, 1e-9));
      }
      expect(faderToMul(0.5), closeTo(0.125, 1e-9));
    });

    test('meter maps -60..0 dB to 0..1', () {
      expect(meterFraction(1), 1);
      expect(meterFraction(0), 0);
      expect(meterFraction(dbToMul(-30)), closeTo(0.5, 1e-9));
      expect(meterFraction(dbToMul(-80)), 0);
    });

    test('formats dB', () {
      expect(formatDb(1), '0.0 dB');
      expect(formatDb(0), '-∞ dB');
    });
  });

  group('DuckingController', () {
    late Map<String, double> volumes;
    late List<String> writes;
    late DuckingController ducking;

    setUp(() {
      volumes = {'Mic': 1.0, 'Música': 0.5};
      writes = [];
      ducking = DuckingController(
        readVolume: (name) async => volumes[name]!,
        writeVolume: (name, mul) async {
          volumes[name] = mul;
          writes.add('$name ${mul.toStringAsFixed(3)}');
        },
      );
    });

    test('lowers the target and restores it when the sound ends', () async {
      await ducking.duck(sound: 'Aplausos', target: 'Música', reductionDb: 20);
      expect(volumes['Música'], closeTo(0.05, 1e-9));
      expect(ducking.isDucked('Música'), isTrue);

      await ducking.release('Aplausos');
      expect(volumes['Música'], 0.5);
      expect(ducking.isDucked('Música'), isFalse);
    });

    test(
      'two sounds on the same target: restore only after both end',
      () async {
        await ducking.duck(sound: 'A', target: 'Mic', reductionDb: 6);
        await ducking.duck(sound: 'B', target: 'Mic', reductionDb: 6);
        expect(writes, hasLength(1), reason: 'second duck must not stack');

        await ducking.release('A');
        expect(volumes['Mic'], lessThan(1));
        await ducking.release('B');
        expect(volumes['Mic'], 1);
      },
    );

    test('ducking twice for the same sound is a no-op', () async {
      await ducking.duck(sound: 'A', target: 'Mic', reductionDb: 10);
      await ducking.duck(sound: 'A', target: 'Mic', reductionDb: 10);
      expect(writes, hasLength(1));
      await ducking.release('A');
      expect(volumes['Mic'], 1);
    });

    test('release of an unknown sound does nothing', () async {
      await ducking.release('nada');
      expect(writes, isEmpty);
    });

    test('panic restores everything', () async {
      await ducking.duck(sound: 'A', target: 'Mic', reductionDb: 10);
      await ducking.duck(sound: 'B', target: 'Música', reductionDb: 10);
      await ducking.releaseAll();
      expect(volumes, {'Mic': 1.0, 'Música': 0.5});
      expect(ducking.duckedTargets, isEmpty);
    });
  });
}
