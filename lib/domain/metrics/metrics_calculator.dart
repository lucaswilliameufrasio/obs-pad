import '../obs_models.dart';

/// One poll of GetStats + GetStreamStatus + GetRecordStatus.
class MetricsSample {
  const MetricsSample({
    required this.time,
    required this.stats,
    required this.stream,
    required this.record,
  });

  final DateTime time;
  final ObsStats stats;
  final ObsStreamStatus stream;
  final ObsRecordStatus record;
}

enum BitrateSource { none, stream, record }

/// Derived values for one sample, ready for cards and charts.
class MetricsPoint {
  const MetricsPoint({
    required this.time,
    required this.sample,
    required this.bitrateSource,
    required this.bitrateKbps,
    required this.renderDropPct,
    required this.outputDropPct,
    required this.recentDropPct,
  });

  final DateTime time;
  final MetricsSample sample;
  final BitrateSource bitrateSource;

  /// null when it cannot be computed (first sample, output restarted).
  final double? bitrateKbps;

  /// Cumulative % of frames skipped by the render thread (GPU/scene too heavy).
  final double renderDropPct;

  /// Cumulative % of frames lost on output: network for the live,
  /// encoder when only recording.
  final double outputDropPct;

  /// % of frames lost (render + output) in the last few seconds; drives the
  /// alert and the "frames perdidos" chart.
  final double recentDropPct;

  double get cpu => sample.stats.cpuUsage;
}

class MetricsAlerts {
  const MetricsAlerts({this.framesDropped = false, this.bitrateDrop = false});

  static const none = MetricsAlerts();

  final bool framesDropped;
  final bool bitrateDrop;

  bool get any => framesDropped || bitrateDrop;

  /// True when this has an alert that [previous] did not have.
  bool isNewComparedTo(MetricsAlerts previous) =>
      (framesDropped && !previous.framesDropped) ||
      (bitrateDrop && !previous.bitrateDrop);
}

/// Pure calculations for the dashboard. Keeps a rolling window of points.
class MetricsCalculator {
  MetricsCalculator({
    this.window = const Duration(minutes: 3),
    this.dropAlertPct = 1.0,
    this.bitrateDropRatio = 0.5,
    this.minBaselineKbps = 300,
    this.baselineSamples = 10,
    this.recentWindow = const Duration(seconds: 10),
  });

  Duration window;

  /// Alert when more than this % of frames were lost recently.
  final double dropAlertPct;

  /// Alert when bitrate falls below this fraction of the recent average.
  final double bitrateDropRatio;

  /// Ignore bitrate drops while the average is tiny (e.g. static scenes).
  final double minBaselineKbps;
  final int baselineSamples;
  final Duration recentWindow;

  final List<MetricsPoint> _points = [];
  List<MetricsPoint> get points => List.unmodifiable(_points);
  MetricsPoint? get latest => _points.lastOrNull;

  void clear() => _points.clear();

  // ---------------------------------------------------------------------------
  // Formulas
  // ---------------------------------------------------------------------------

  /// kbit/s from the outputBytes delta between two samples.
  static double? bitrateKbps({
    required int previousBytes,
    required int currentBytes,
    required Duration elapsed,
  }) {
    if (elapsed <= Duration.zero) return null;
    // Bytes going backwards = the output was restarted.
    if (currentBytes < previousBytes) return null;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    return (currentBytes - previousBytes) * 8 / 1000 / seconds;
  }

  static double dropPercent(int skipped, int total) =>
      total <= 0 ? 0 : (skipped / total * 100).clamp(0, 100).toDouble();

  // ---------------------------------------------------------------------------
  // Rolling state
  // ---------------------------------------------------------------------------

  MetricsPoint add(MetricsSample sample) {
    final previous = _points.lastOrNull?.sample;
    final source = sample.stream.active
        ? BitrateSource.stream
        : sample.record.active
        ? BitrateSource.record
        : BitrateSource.none;

    double? bitrate;
    if (previous != null && source != BitrateSource.none) {
      final (prevBytes, prevActive, currBytes) = source == BitrateSource.stream
          ? (previous.stream.bytes, previous.stream.active, sample.stream.bytes)
          : (
              previous.record.bytes,
              previous.record.active,
              sample.record.bytes,
            );
      if (prevActive) {
        bitrate = bitrateKbps(
          previousBytes: prevBytes,
          currentBytes: currBytes,
          elapsed: sample.time.difference(previous.time),
        );
      }
    }

    final stats = sample.stats;
    final outputDrop = sample.stream.active
        ? dropPercent(sample.stream.skippedFrames, sample.stream.totalFrames)
        : dropPercent(stats.outputSkippedFrames, stats.outputTotalFrames);

    final point = MetricsPoint(
      time: sample.time,
      sample: sample,
      bitrateSource: source,
      bitrateKbps: bitrate,
      renderDropPct: dropPercent(
        stats.renderSkippedFrames,
        stats.renderTotalFrames,
      ),
      outputDropPct: outputDrop,
      recentDropPct: _recentDrop(sample),
    );
    _points.add(point);
    _trim(sample.time);
    return point;
  }

  /// Frames lost (render + output/network) over [recentWindow], in %.
  double _recentDrop(MetricsSample current) {
    final since = current.time.subtract(recentWindow);
    final base = _points
        .where((p) => !p.time.isBefore(since))
        .firstOrNull
        ?.sample;
    if (base == null) return 0;

    int delta(int now, int before) => now >= before ? now - before : now;
    final s = current.stats;
    final b = base.stats;
    final renderSkipped = delta(s.renderSkippedFrames, b.renderSkippedFrames);
    final renderTotal = delta(s.renderTotalFrames, b.renderTotalFrames);

    final (outSkipped, outTotal) = current.stream.active && base.stream.active
        ? (
            delta(current.stream.skippedFrames, base.stream.skippedFrames),
            delta(current.stream.totalFrames, base.stream.totalFrames),
          )
        : (
            delta(s.outputSkippedFrames, b.outputSkippedFrames),
            delta(s.outputTotalFrames, b.outputTotalFrames),
          );

    final render = dropPercent(renderSkipped, renderTotal);
    final output = dropPercent(outSkipped, outTotal);
    return render > output ? render : output;
  }

  void _trim(DateTime now) {
    final cutoff = now.subtract(window);
    _points.removeWhere((p) => p.time.isBefore(cutoff));
  }

  MetricsAlerts alerts() {
    final last = latest;
    if (last == null) return MetricsAlerts.none;
    final framesDropped = last.recentDropPct > dropAlertPct;

    var bitrateDrop = false;
    final current = last.bitrateKbps;
    if (current != null && last.bitrateSource == BitrateSource.stream) {
      final previous = _points
          .take(_points.length - 1)
          .where((p) => p.bitrateSource == BitrateSource.stream)
          .map((p) => p.bitrateKbps)
          .nonNulls
          .toList();
      if (previous.length >= baselineSamples ~/ 2) {
        final recent = previous.length > baselineSamples
            ? previous.sublist(previous.length - baselineSamples)
            : previous;
        final average = recent.reduce((a, b) => a + b) / recent.length;
        bitrateDrop =
            average >= minBaselineKbps && current < average * bitrateDropRatio;
      }
    }
    return MetricsAlerts(
      framesDropped: framesDropped,
      bitrateDrop: bitrateDrop,
    );
  }
}
