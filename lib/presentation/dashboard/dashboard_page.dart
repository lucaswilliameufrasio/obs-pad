import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/metrics/metrics_calculator.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'metrics_controller.dart';

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(isConnectedProvider)) {
      return EmptyState(icon: Icons.link_off, message: l.failNotConnectedTitle);
    }
    final metrics = ref.watch(metricsProvider);
    final latest = metrics.latest;
    if (latest == null) return const Center(child: CircularProgressIndicator());

    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final sample = latest.sample;
    final stream = sample.stream;
    final record = sample.record;
    final stats = sample.stats;
    final colors = Theme.of(context).colorScheme;
    final windowMinutes = ref.watch(
      settingsProvider.select((s) => s.chartWindowMinutes),
    );

    final dropCritical = latest.recentDropPct > 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        if (metrics.alerts.framesDropped)
          HintCard(
            warning: true,
            icon: Icons.warning_amber_rounded,
            title: l.alertFramesTitle,
            text: l.alertFramesBody,
          ),
        if (metrics.alerts.bitrateDrop)
          HintCard(
            warning: true,
            icon: Icons.network_check,
            title: l.alertBitrateTitle,
            text: l.alertBitrateBody,
          ),
        GridView.extent(
          maxCrossAxisExtent: 220,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _MetricCard(
              icon: Icons.sensors,
              label: l.metricLive,
              value: stream.active
                  ? (stream.reconnecting
                        ? l.statusReconnectingShort
                        : l.badgeLive)
                  : l.metricOff,
              highlight: stream.active ? Colors.red : null,
            ),
            _MetricCard(
              icon: Icons.fiber_manual_record,
              label: l.metricRecording,
              value: record.active
                  ? (record.paused
                        ? l.badgePaused
                        : formatDuration(record.duration))
                  : l.metricOff,
              highlight: record.active ? Colors.pink : null,
            ),
            _MetricCard(
              icon: Icons.timer_outlined,
              label: l.metricAirTime,
              value: stream.active
                  ? formatDuration(stream.duration)
                  : '--:--:--',
            ),
            _MetricCard(
              icon: Icons.speed,
              label: l.metricBitrate,
              value: latest.bitrateKbps == null
                  ? '—'
                  : '${number.format(latest.bitrateKbps!.round())} kb/s',
              highlight: metrics.alerts.bitrateDrop ? colors.error : null,
            ),
            _MetricCard(
              icon: Icons.memory,
              label: l.metricCpu,
              value: '${stats.cpuUsage.toStringAsFixed(1)} %',
              highlight: stats.cpuUsage > 80 ? colors.error : null,
            ),
            _MetricCard(
              icon: Icons.storage,
              label: l.metricMemory,
              value: '${number.format(stats.memoryUsageMb.round())} MB',
            ),
            _MetricCard(
              icon: Icons.movie_filter_outlined,
              label: l.metricFps,
              value: stats.activeFps.toStringAsFixed(1),
            ),
            _MetricCard(
              icon: Icons.brush_outlined,
              label: l.metricRenderDropped,
              value:
                  '${number.format(stats.renderSkippedFrames)} '
                  '(${latest.renderDropPct.toStringAsFixed(1)} %)',
              highlight: latest.renderDropPct > 1 ? colors.error : null,
            ),
            _MetricCard(
              icon: Icons.upload_outlined,
              label: l.metricOutputDropped,
              value: '${latest.outputDropPct.toStringAsFixed(2)} %',
              highlight: latest.outputDropPct > 1 || dropCritical
                  ? colors.error
                  : null,
            ),
            _MetricCard(
              icon: Icons.traffic_outlined,
              label: l.metricCongestion,
              value: stream.active
                  ? '${(stream.congestion * 100).toStringAsFixed(0)} %'
                  : '—',
              highlight: stream.congestion > 0.5 ? colors.error : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l.chartWindow,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final m in [2, 3, 4, 5])
                  ButtonSegment(value: m, label: Text('$m min')),
              ],
              selected: {windowMinutes},
              onSelectionChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .update((s) => s.copyWith(chartWindowMinutes: v.first)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ChartCard(
          title: l.chartBitrate,
          unit: 'kb/s',
          color: Colors.blue,
          points: metrics.points,
          window: Duration(minutes: windowMinutes),
          valueOf: (p) => p.bitrateKbps,
        ),
        _ChartCard(
          title: l.chartCpu,
          unit: '%',
          color: Colors.orange,
          points: metrics.points,
          window: Duration(minutes: windowMinutes),
          valueOf: (p) => p.cpu,
          fixedMax: 100,
        ),
        _ChartCard(
          title: l.chartDropped,
          unit: '%',
          color: Colors.red,
          points: metrics.points,
          window: Duration(minutes: windowMinutes),
          valueOf: (p) => p.recentDropPct,
          threshold: 1,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = highlight;
    return Card(
      elevation: 0,
      color: accent == null
          ? colors.surfaceContainerHigh
          : Color.alphaBlend(accent.withValues(alpha: 0.2), colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: accent == null
            ? BorderSide.none
            : BorderSide(color: accent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent ?? colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.points,
    required this.window,
    required this.valueOf,
    this.fixedMax,
    this.threshold,
  });

  final String title;
  final String unit;
  final Color color;
  final List<MetricsPoint> points;
  final Duration window;
  final double? Function(MetricsPoint) valueOf;
  final double? fixedMax;
  final double? threshold;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = points.lastOrNull?.time ?? DateTime.now();
    final windowSeconds = window.inSeconds.toDouble();
    // x = seconds relative to now (-window..0); gaps where value is null.
    final spots = <FlSpot>[
      for (final p in points)
        if (valueOf(p) case final v?)
          FlSpot(p.time.difference(now).inMilliseconds / 1000, v)
        else
          FlSpot.nullSpot,
    ];
    final values = spots.where((s) => !s.isNull()).map((s) => s.y);
    final maxValue = values.isEmpty ? 1.0 : values.reduce(math.max);
    final maxY =
        fixedMax ??
        math.max(maxValue * 1.2, threshold == null ? 1 : threshold! * 2);
    final latest = values.isEmpty ? null : values.last;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (latest != null)
                  Text(
                    '${latest.toStringAsFixed(latest >= 100 ? 0 : 1)} $unit',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: LineChart(
                duration: Duration.zero,
                LineChartData(
                  minX: -windowSeconds,
                  maxX: 0,
                  minY: 0,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  lineTouchData: const LineTouchData(enabled: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: threshold == null
                      ? null
                      : ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: threshold!,
                              color: colors.error,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value >= 1000
                                ? '${(value / 1000).toStringAsFixed(1)}k'
                                : value.toStringAsFixed(value < 10 ? 1 : 0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 60,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value == 0 ? '0' : '${(value / 60).round()}m',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: color,
                      barWidth: 2,
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
