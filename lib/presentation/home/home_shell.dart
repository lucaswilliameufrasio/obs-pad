import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/obs_models.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/metrics_controller.dart';
import '../mixer/mixer_page.dart';
import '../providers.dart';
import '../widgets/connection_banner.dart';

/// Bottom navigation + app bar + connection banner around every tab.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Sockets often die while the phone sleeps: retry right away on resume.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(obsRepositoryProvider).retryNow(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(connectionStatusProvider);
      if (status is ObsDisconnected || status is ObsConnectionFailed) {
        unawaited(ref.read(connectionControllerProvider).connectActive());
      }
      _applyWakelock(ref.read(settingsProvider).keepScreenOn);
    });
  }

  void _applyWakelock(bool enabled) {
    unawaited(WakelockPlus.toggle(enable: enabled).catchError((Object _) {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.listen(
      settingsProvider.select((s) => s.keepScreenOn),
      (_, enabled) => _applyWakelock(enabled),
    );
    final index = widget.navigationShell.currentIndex;
    if (ref.read(activeTabProvider) != index) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(activeTabProvider.notifier).set(index),
      );
    }
    // Metrics are polled app-wide so alerts reach the user on any tab.
    final alerts = ref.watch(metricsProvider.select((m) => m.alerts));
    final profile = ref.watch(profilesProvider).active;
    final status = ref.watch(connectionStatusProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.push('/profiles'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: switch (status) {
                    ObsConnected() => Colors.green,
                    ObsConnecting() || ObsReconnecting() => Colors.orange,
                    _ => colors.error,
                  },
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    profile?.name ?? l.appTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              _menuItem('/profiles', Icons.computer, l.menuProfiles),
              _menuItem('/remote', Icons.public, l.menuRemote),
              _menuItem('/onboarding', Icons.school_outlined, l.menuGuide),
              _menuItem('/settings', Icons.settings_outlined, l.menuSettings),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          if (alerts.any && index != 3)
            Material(
              color: colors.error,
              child: InkWell(
                onTap: () => widget.navigationShell.goBranch(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colors.onError),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alerts.framesDropped
                              ? l.alertFramesTitle
                              : l.alertBitrateTitle,
                          style: TextStyle(color: colors.onError),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.onError),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l.navPad,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: l.navMixer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.music_note_outlined),
            selectedIcon: const Icon(Icons.music_note),
            label: l.navSounds,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_heart_outlined),
            selectedIcon: const Icon(Icons.monitor_heart),
            label: l.navMetrics,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String route, IconData icon, String label) =>
      PopupMenuItem(
        value: route,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          contentPadding: EdgeInsets.zero,
        ),
      );
}
