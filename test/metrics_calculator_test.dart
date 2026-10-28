import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/domain/metrics/metrics_calculator.dart';
import 'package:obs_pad/domain/obs_models.dart';

final t0 = DateTime(2026, 10, 28, 20);

ObsStats stats({
  int renderSkipped = 0,
  int renderTotal = 0,
  int outputSkipped = 0,
  int outputTotal = 0,
  double cpu = 10,
}) => ObsStats(
  cpuUsage: cpu,
  memoryUsageMb: 512,
  activeFps: 60,
  averageFrameRenderTimeMs: 2,
  renderSkippedFrames: renderSkipped,
  renderTotalFrames: renderTotal,
  outputSkippedFrames: outputSkipped,
  outputTotalFrames: outputTotal,
);

ObsStreamStatus live({
  required int bytes,
  int skipped = 0,
  int total = 0,
  double congestion = 0,
}) => ObsStreamStatus(
  active: true,
  reconnecting: false,
  duration: Duration.zero,
  congestion: congestion,
  bytes: bytes,
  skippedFrames: skipped,
  totalFrames: total,
);

MetricsSample sample(
  int second, {
  ObsStats? s,
  ObsStreamStatus stream = ObsStreamStatus.inactive,
  ObsRecordStatus record = ObsRecordStatus.inactive,
}) => MetricsSample(
  time: t0.add(Duration(seconds: second)),
  stats: s ?? stats(),
  stream: stream,
  record: record,
);

void main() {
  group('bitrate from outputBytes delta', () {
    test('6000 kbps = 750000 bytes in one second', () {
      expect(
        MetricsCalculator.bitrateKbps(
          previousBytes: 1000000,
          currentBytes: 1750000,
          elapsed: const Duration(seconds: 1),
        ),
        closeTo(6000, 0.001),
      );
    });

    test('uses the real elapsed time, not a fixed 1 s', () {
      expect(
        MetricsCalculator.bitrateKbps(
          previousBytes: 0,
          currentBytes: 750000,
          elapsed: const Duration(milliseconds: 1500),
        ),
        closeTo(4000, 0.001),
      );
    });

    test('bytes going backwards (output restarted) gives no value', () {
      expect(
        MetricsCalculator.bitrateKbps(
          previousBytes: 5000,
          currentBytes: 100,
          elapsed: const Duration(seconds: 1),
        ),
        isNull,
      );
    });

    test('zero elapsed time gives no value', () {
      expect(
        MetricsCalculator.bitrateKbps(
          previousBytes: 0,
          currentBytes: 10,
          elapsed: Duration.zero,
        ),
        isNull,
      );
    });

    test('first sample has no bitrate, second one has', () {
      final calc = MetricsCalculator();
      expect(calc.add(sample(0, stream: live(bytes: 0))).bitrateKbps, isNull);
      final point = calc.add(sample(1, stream: live(bytes: 500000)));
      expect(point.bitrateKbps, closeTo(4000, 0.001));
      expect(point.bitrateSource, BitrateSource.stream);
    });

    test('falls back to recording bytes when not live', () {
      final calc = MetricsCalculator();
      const rec = ObsRecordStatus(
        active: true,
        paused: false,
        duration: Duration.zero,
        bytes: 0,
      );
      calc.add(sample(0, record: rec));
      final point = calc.add(
        sample(
          1,
          record: const ObsRecordStatus(
            active: true,
            paused: false,
            duration: Duration.zero,
            bytes: 1250000,
          ),
        ),
      );
      expect(point.bitrateSource, BitrateSource.record);
      expect(point.bitrateKbps, closeTo(10000, 0.001));
    });

    test('no bitrate on the first sample after the live starts', () {
      final calc = MetricsCalculator();
      calc.add(sample(0));
      expect(
        calc.add(sample(1, stream: live(bytes: 9999))).bitrateKbps,
        isNull,
      );
    });
  });

  group('dropped frames', () {
    test('percent handles zero totals', () {
      expect(MetricsCalculator.dropPercent(0, 0), 0);
      expect(MetricsCalculator.dropPercent(5, 500), closeTo(1, 0.0001));
    });

    test('output drop uses the stream counters while live', () {
      final calc = MetricsCalculator();
      final point = calc.add(
        sample(
          0,
          s: stats(outputSkipped: 0, outputTotal: 1000),
          stream: live(bytes: 0, skipped: 30, total: 1000),
        ),
      );
      expect(point.outputDropPct, closeTo(3, 0.0001));
    });

    test('recent drop only looks at the last seconds', () {
      final calc = MetricsCalculator(recentWindow: const Duration(seconds: 10));
      // Lots of old drops...
      calc.add(sample(0, s: stats(renderSkipped: 500, renderTotal: 1000)));
      for (var i = 1; i <= 20; i++) {
        calc.add(
          sample(i, s: stats(renderSkipped: 500, renderTotal: 1000 + i * 60)),
        );
      }
      // ...but nothing new: no alert.
      expect(calc.latest!.renderDropPct, greaterThan(1));
      expect(calc.latest!.recentDropPct, 0);
      expect(calc.alerts().framesDropped, isFalse);
    });

    test('alert when more than 1% of recent frames are lost', () {
      final calc = MetricsCalculator();
      calc.add(sample(0, stream: live(bytes: 0, skipped: 0, total: 0)));
      calc.add(sample(1, stream: live(bytes: 1, skipped: 1, total: 60)));
      // 1/60 = 1.67 %
      expect(calc.latest!.recentDropPct, closeTo(1.666, 0.01));
      expect(calc.alerts().framesDropped, isTrue);
    });

    test('exactly 1% does not alert', () {
      final calc = MetricsCalculator();
      calc.add(sample(0, s: stats(outputSkipped: 0, outputTotal: 0)));
      calc.add(sample(1, s: stats(outputSkipped: 1, outputTotal: 100)));
      expect(calc.alerts().framesDropped, isFalse);
    });
  });

  group('bitrate drop alert', () {
    MetricsCalculator steadyLive({int kbps = 6000, int seconds = 10}) {
      final calc = MetricsCalculator();
      for (var i = 0; i <= seconds; i++) {
        calc.add(sample(i, stream: live(bytes: i * kbps * 1000 ~/ 8)));
      }
      return calc;
    }

    test('steady bitrate does not alert', () {
      expect(steadyLive().alerts().bitrateDrop, isFalse);
    });

    test('falling below half of the recent average alerts', () {
      final calc = steadyLive();
      final last = calc.latest!.sample.stream.bytes;
      calc.add(sample(11, stream: live(bytes: last + 2000 * 1000 ~/ 8)));
      expect(calc.latest!.bitrateKbps, closeTo(2000, 0.01));
      expect(calc.alerts().bitrateDrop, isTrue);
    });

    test('a small dip does not alert', () {
      final calc = steadyLive();
      final last = calc.latest!.sample.stream.bytes;
      calc.add(sample(11, stream: live(bytes: last + 5000 * 1000 ~/ 8)));
      expect(calc.alerts().bitrateDrop, isFalse);
    });

    test('ignores very low baselines (static scene)', () {
      final calc = steadyLive(kbps: 100);
      final last = calc.latest!.sample.stream.bytes;
      calc.add(sample(11, stream: live(bytes: last + 10)));
      expect(calc.alerts().bitrateDrop, isFalse);
    });

    test('new alert detection', () {
      const none = MetricsAlerts.none;
      const frames = MetricsAlerts(framesDropped: true);
      const both = MetricsAlerts(framesDropped: true, bitrateDrop: true);
      expect(frames.isNewComparedTo(none), isTrue);
      expect(frames.isNewComparedTo(frames), isFalse);
      expect(both.isNewComparedTo(frames), isTrue);
      expect(none.isNewComparedTo(both), isFalse);
    });
  });

  test('keeps only the configured window of history', () {
    final calc = MetricsCalculator(window: const Duration(minutes: 2));
    for (var i = 0; i <= 300; i++) {
      calc.add(sample(i, stream: live(bytes: i * 1000)));
    }
    expect(calc.points.first.time, t0.add(const Duration(seconds: 180)));
    expect(calc.points, hasLength(121));
  });
}
