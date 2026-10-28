import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../providers.dart';

Future<void> switchScene(
  BuildContext context,
  WidgetRef ref,
  String sceneName,
) async {
  tapFeedback(ref);
  await runObs(
    context,
    () => ref.read(obsRepositoryProvider).setCurrentProgramScene(sceneName),
  );
}

/// Horizontal list of scenes; the one on air is highlighted.
class SceneStrip extends ConsumerWidget {
  const SceneStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(obsLiveStateProvider);
    final l = AppLocalizations.of(context);
    if (live.scenes.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: live.scenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scene = live.scenes[index];
          final onAir = scene.name == live.currentScene;
          return ChoiceChip(
            key: ValueKey('scene-${scene.name}'),
            avatar: onAir ? const Icon(Icons.videocam, size: 18) : null,
            label: Text(scene.name),
            tooltip: onAir ? l.onAir : null,
            selected: onAir,
            showCheckmark: false,
            onSelected: (_) => switchScene(context, ref, scene.name),
          );
        },
      ),
    );
  }
}

/// Full grid of scenes (big touch targets).
class SceneGrid extends ConsumerWidget {
  const SceneGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final live = ref.watch(obsLiveStateProvider);
    final colors = Theme.of(context).colorScheme;
    if (!live.loaded) return const Center(child: CircularProgressIndicator());
    if (live.scenes.isEmpty) return Center(child: Text(l.scenesEmpty));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: live.scenes.length,
      itemBuilder: (context, index) {
        final scene = live.scenes[index];
        final onAir = scene.name == live.currentScene;
        return Material(
          color: onAir ? colors.primary : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => switchScene(context, ref, scene.name),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    onAir ? Icons.videocam : Icons.videocam_outlined,
                    color: onAir ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scene.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onAir ? colors.onPrimary : colors.onSurface,
                      fontWeight: onAir ? FontWeight.bold : null,
                    ),
                  ),
                  if (onAir)
                    Text(
                      l.onAir,
                      style: TextStyle(color: colors.onPrimary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
