import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/audio_math.dart';
import '../../domain/obs_events.dart';
import '../../domain/obs_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Index of the bottom tab on screen (set by the home shell).
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(
  ActiveTabNotifier.new,
);

const mixerTabIndex = 1;

/// Peak level per input. Subscribes to the high-volume InputVolumeMeters
/// event only while the mixer tab is the one on screen.
class VolumeMetersNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    final visible = ref.watch(activeTabProvider) == mixerTabIndex;
    final connected = ref.watch(isConnectedProvider);
    if (!visible || !connected) return const {};

    final repo = ref.read(obsRepositoryProvider);
    unawaited(_setMeters(enabled: true));
    final sub = ref.watch(obsEventsProvider).listen((event) {
      if (event is InputVolumeMeters) state = event.peaks;
    });
    ref.onDispose(() {
      unawaited(sub.cancel());
      unawaited(
        repo.setVolumeMetersEnabled(enabled: false).catchError((Object _) {}),
      );
    });
    return const {};
  }

  Future<void> _setMeters({required bool enabled}) async {
    try {
      await ref
          .read(obsRepositoryProvider)
          .setVolumeMetersEnabled(enabled: enabled);
    } on Exception {
      // Connection problem: the banner already tells the user.
    }
  }
}

final volumeMetersProvider =
    NotifierProvider<VolumeMetersNotifier, Map<String, double>>(
      VolumeMetersNotifier.new,
    );

class MixerPage extends ConsumerWidget {
  const MixerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final live = ref.watch(obsLiveStateProvider);
    if (!ref.watch(isConnectedProvider)) {
      return EmptyState(icon: Icons.link_off, message: l.failNotConnectedTitle);
    }
    if (!live.loaded) return const Center(child: CircularProgressIndicator());
    if (live.audioInputs.isEmpty) {
      return EmptyState(icon: Icons.volume_off, message: l.mixerEmpty);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      itemCount: live.audioInputs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _InputStrip(
        key: ValueKey(live.audioInputs[i].name),
        input: live.audioInputs[i],
      ),
    );
  }
}

class _InputStrip extends ConsumerStatefulWidget {
  const _InputStrip({required this.input, super.key});

  final ObsAudioInput input;

  @override
  ConsumerState<_InputStrip> createState() => _InputStripState();
}

class _InputStripState extends ConsumerState<_InputStrip> {
  /// Fader position while the finger is on the slider.
  double? _dragging;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _send(double position, {bool force = false}) async {
    final now = DateTime.now();
    // Throttle to ~20 requests/s while dragging.
    if (!force &&
        now.difference(_lastSent) < const Duration(milliseconds: 50)) {
      return;
    }
    _lastSent = now;
    await runObs(
      context,
      () => ref
          .read(obsRepositoryProvider)
          .setInputVolume(widget.input.name, faderToMul(position)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final input = widget.input;
    final peak = ref.watch(
      volumeMetersProvider.select((m) => m[input.name] ?? 0),
    );
    final position = _dragging ?? mulToFader(input.volumeMul);
    final muted = input.muted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    input.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatDb(faderToMul(position)),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                IconButton.filledTonal(
                  key: ValueKey('mute-${input.name}'),
                  tooltip: muted ? l.unmute : l.mute,
                  isSelected: muted,
                  style: IconButton.styleFrom(
                    backgroundColor: muted ? colors.errorContainer : null,
                    foregroundColor: muted ? colors.onErrorContainer : null,
                  ),
                  icon: const Icon(Icons.volume_up),
                  selectedIcon: const Icon(Icons.volume_off),
                  onPressed: () {
                    tapFeedback(ref);
                    unawaited(
                      runObs(
                        context,
                        () => ref
                            .read(obsRepositoryProvider)
                            .setInputMute(input.name, muted: !muted),
                      ),
                    );
                  },
                ),
              ],
            ),
            _LevelMeter(level: muted ? 0 : meterFraction(peak), muted: muted),
            Slider(
              value: position,
              semanticFormatterCallback: (v) => formatDb(faderToMul(v)),
              onChangeStart: (v) => setState(() => _dragging = v),
              onChanged: (v) {
                setState(() => _dragging = v);
                unawaited(_send(v));
              },
              onChangeEnd: (v) async {
                await _send(v, force: true);
                if (mounted) setState(() => _dragging = null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Green/yellow/red bar on a -60..0 dB scale.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level, required this.muted});

  final double level;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 10,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(color: colors.surfaceContainerHighest),
                // The gradient always spans the full width; only the
                // filled part is revealed, so red means "near 0 dB".
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: level,
                    child: Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: muted
                              ? [colors.outline, colors.outline]
                              : const [Colors.green, Colors.yellow, Colors.red],
                          stops: muted ? null : const [0.6, 0.85, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
