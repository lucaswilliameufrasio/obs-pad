import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/metrics/metrics_calculator.dart';
import '../../domain/obs_failure.dart';
import '../providers.dart';

class MetricsState {
  const MetricsState({
    this.points = const [],
    this.alerts = MetricsAlerts.none,
  });

  final List<MetricsPoint> points;
  final MetricsAlerts alerts;

  MetricsPoint? get latest => points.lastOrNull;
}

/// Polls GetStats + GetStreamStatus + GetRecordStatus every second while
/// connected, and raises alerts (color + vibration).
class MetricsNotifier extends Notifier<MetricsState> {
  static const interval = Duration(seconds: 1);

  late MetricsCalculator _calculator;
  bool _inFlight = false;

  @override
  MetricsState build() {
    final minutes = ref.watch(
      settingsProvider.select((s) => s.chartWindowMinutes),
    );
    _calculator = MetricsCalculator(window: Duration(minutes: minutes));
    if (!ref.watch(isConnectedProvider)) return const MetricsState();

    final timer = Timer.periodic(interval, (_) => unawaited(_poll()));
    ref.onDispose(timer.cancel);
    unawaited(_poll());
    return const MetricsState();
  }

  Future<void> _poll() async {
    if (_inFlight) return;
    _inFlight = true;
    final repo = ref.read(obsRepositoryProvider);
    try {
      final (stats, stream, record) = await (
        repo.getStats(),
        repo.getStreamStatus(),
        repo.getRecordStatus(),
      ).wait;
      if (!ref.mounted) return;
      _calculator.add(
        MetricsSample(
          time: DateTime.now(),
          stats: stats,
          stream: stream,
          record: record,
        ),
      );
      final alerts = _calculator.alerts();
      if (alerts.isNewComparedTo(state.alerts) &&
          ref.read(settingsProvider).haptics) {
        unawaited(HapticFeedback.heavyImpact());
        unawaited(HapticFeedback.vibrate());
      }
      state = MetricsState(points: _calculator.points, alerts: alerts);
    } on ParallelWaitError<dynamic, dynamic> {
      // Lost connection; the status banner handles it.
    } on ObsFailure {
      // Same.
    } finally {
      _inFlight = false;
    }
  }
}

final metricsProvider = NotifierProvider<MetricsNotifier, MetricsState>(
  MetricsNotifier.new,
);
