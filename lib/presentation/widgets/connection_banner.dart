import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/obs_models.dart';
import '../../l10n/app_localizations.dart';
import '../failure_text.dart';
import '../providers.dart';

/// Status strip shown under the app bar whenever we are not connected.
class ConnectionBanner extends ConsumerStatefulWidget {
  const ConnectionBanner({super.key});

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  Timer? _ticker;
  DateTime? _retryAt;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _trackCountdown(ObsConnectionStatus status) {
    _ticker?.cancel();
    if (status is ObsReconnecting) {
      _retryAt = DateTime.now().add(status.nextRetry);
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() {}) : null,
      );
    } else {
      _retryAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    ref.listen(connectionStatusProvider, (_, next) => _trackCountdown(next));
    final status = ref.watch(connectionStatusProvider);
    if (status is ObsReconnecting && _retryAt == null) _trackCountdown(status);

    final (
      Color bg,
      Color fg,
      IconData icon,
      String text,
      Widget? action,
    ) = switch (status) {
      ObsConnected() => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle,
        l.statusConnected,
        null,
      ),
      ObsConnecting() => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.sync,
        l.statusConnecting,
        null,
      ),
      ObsReconnecting(:final attempt) => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.wifi_off,
        l.statusReconnecting(_secondsLeft(), attempt),
        TextButton(
          onPressed: () => ref.read(obsRepositoryProvider).retryNow(),
          child: Text(l.tryNow),
        ),
      ),
      ObsConnectionFailed(:final failure) => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline,
        l.statusFailed(describeFailure(l, failure).title),
        TextButton(
          onPressed: () => context.push('/profiles'),
          child: Text(l.edit),
        ),
      ),
      ObsDisconnected() => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        Icons.link_off,
        l.statusDisconnected,
        TextButton(
          onPressed: () =>
              ref.read(connectionControllerProvider).connectActive(),
          child: Text(l.connect),
        ),
      ),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: status is ObsConnected
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Material(
                color: bg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  child: Row(
                    children: [
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(text, style: TextStyle(color: fg)),
                      ),
                      ?action,
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  int _secondsLeft() {
    final at = _retryAt;
    if (at == null) return 0;
    final left = at.difference(DateTime.now()).inSeconds + 1;
    return left.clamp(0, 999);
  }
}
