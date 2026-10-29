import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/obs_failure.dart';
import '../../domain/sound/sound_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../pad/pad_tile.dart';
import '../providers.dart';
import '../widgets/catalog.dart';
import '../widgets/common.dart';
import 'soundboard_controller.dart';

class SoundboardPage extends ConsumerStatefulWidget {
  const SoundboardPage({super.key});

  @override
  ConsumerState<SoundboardPage> createState() => _SoundboardPageState();
}

class _SoundboardPageState extends ConsumerState<SoundboardPage> {
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();
  String? _pageId;
  bool _editing = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  SoundPage _currentPage(SoundboardProfile profile) =>
      profile.pages.where((p) => p.id == _pageId).firstOrNull ??
      profile.pages.first;

  /// Errors on pads get a sound-specific explanation.
  void _showError(Object error, SoundPad pad, String pageId) {
    final l = AppLocalizations.of(context);
    if (error is ObsFailure && error.kind == ObsFailureKind.resourceNotFound) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.soundMissing(pad.inputName)),
            action: SnackBarAction(
              label: l.edit,
              onPressed: () => context.push('/sounds/pad/$pageId/${pad.id}'),
            ),
          ),
        );
    } else if (error is ObsFailure &&
        error.kind == ObsFailureKind.soundNotOnAir) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.soundNotOnAir(pad.inputName)),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: l.soundAddToAllScenes,
              onPressed: () => unawaited(_addToAllScenesAndPlay(pad, pageId)),
            ),
          ),
        );
    } else {
      showFailureSnack(context, error);
    }
  }

  Future<void> _addToAllScenesAndPlay(SoundPad pad, String pageId) => _run(
    () async {
      final scenes = ref
          .read(obsLiveStateProvider)
          .scenes
          .map((s) => s.name)
          .toList();
      await ref
          .read(obsRepositoryProvider)
          .addInputToScenes(pad.inputName, scenes);
      await ref.read(soundPlayerProvider).start(pad);
    },
    pad,
    pageId,
  );

  Future<void> _run(
    Future<void> Function() action,
    SoundPad pad,
    String pageId,
  ) async {
    try {
      await action();
    } on Exception catch (error) {
      if (mounted) _showError(error, pad, pageId);
    }
  }

  void _tap(SoundPad pad, String pageId, {required bool playing}) {
    tapFeedback(ref);
    final player = ref.read(soundPlayerProvider);
    unawaited(
      _run(() => playing ? player.stop(pad) : player.start(pad), pad, pageId),
    );
  }

  Future<void> _panic() async {
    final l = AppLocalizations.of(context);
    unawaited(HapticFeedback.heavyImpact());
    try {
      final failed = await ref.read(soundPlayerProvider).stopAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(failed == 0 ? l.panicDone : l.panicPartial(failed)),
          ),
        );
    } on Exception catch (error) {
      if (mounted) showFailureSnack(context, error);
    }
  }

  Future<void> _padMenu(SoundPad pad, String pageId, bool playing) async {
    final l = AppLocalizations.of(context);
    final player = ref.read(soundPlayerProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(pad.label), subtitle: Text(pad.inputName)),
            ListTile(
              leading: const Icon(Icons.replay),
              title: Text(l.soundPlayFromStart),
              onTap: () => Navigator.pop(context, 'restart'),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(l.soundResume),
              onTap: () => Navigator.pop(context, 'play'),
            ),
            ListTile(
              leading: const Icon(Icons.pause),
              title: Text(l.soundPause),
              onTap: () => Navigator.pop(context, 'pause'),
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: Text(l.soundStop),
              onTap: () => Navigator.pop(context, 'stop'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.edit),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.delete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'restart':
        await _run(() => player.start(pad), pad, pageId);
      case 'play':
        await _run(() => player.resume(pad), pad, pageId);
      case 'pause':
        await _run(() => player.pause(pad), pad, pageId);
      case 'stop':
        await _run(() => player.stop(pad), pad, pageId);
      case 'edit':
        await context.push('/sounds/pad/$pageId/${pad.id}');
      case 'delete':
        await ref.read(soundboardProvider.notifier).deletePad(pageId, pad.id);
    }
  }

  Future<String?> _askName(String title, [String initial = '']) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.fieldName),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _menu(
    String value,
    SoundboardProfile profile,
    SoundPage page,
  ) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(soundboardProvider.notifier);
    switch (value) {
      case 'page-new':
        final name = await _askName(l.soundPageNew);
        if (name != null && name.isNotEmpty) {
          final id = await notifier.addPage(name);
          setState(() => _pageId = id);
        }
      case 'page-rename':
        final name = await _askName(l.soundPageRename, page.name);
        if (name != null && name.isNotEmpty) {
          await notifier.renamePage(page.id, name);
        }
      case 'page-delete':
        await notifier.deletePage(page.id);
        setState(() => _pageId = null);
      case 'profile-new':
        final name = await _askName(l.soundProfileNew);
        if (name != null && name.isNotEmpty) {
          await notifier.addProfile(name);
          setState(() => _pageId = null);
        }
      case 'profile-rename':
        final name = await _askName(l.soundProfileRename, profile.name);
        if (name != null && name.isNotEmpty) await notifier.renameProfile(name);
      case 'profile-delete':
        await notifier.deleteActiveProfile();
        setState(() => _pageId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final board = ref.watch(soundboardProvider);
    final profile = ref.watch(activeSoundboardProvider);
    final page = _currentPage(profile);
    final playing = ref.watch(
      obsLiveStateProvider.select((s) => s.playingMedia),
    );
    // Keep the player (and its ducking event listener) alive with the tab.
    ref.watch(soundPlayerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-sound',
        onPressed: () => context.push('/sounds/add/${page.id}'),
        icon: const Icon(Icons.add),
        label: Text(l.soundAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                if (board.items.length > 1)
                  PopupMenuButton<String>(
                    tooltip: l.soundProfiles,
                    onSelected: (id) {
                      unawaited(
                        ref
                            .read(soundboardProvider.notifier)
                            .setActiveProfile(id),
                      );
                      setState(() => _pageId = null);
                    },
                    itemBuilder: (_) => [
                      for (final p in board.items)
                        CheckedPopupMenuItem(
                          value: p.id,
                          checked: p.id == profile.id,
                          child: Text(p.name),
                        ),
                    ],
                    child: Chip(
                      avatar: const Icon(
                        Icons.folder_special_outlined,
                        size: 18,
                      ),
                      label: Text(profile.name),
                    ),
                  ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('btn-panic'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  onPressed: _panic,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l.panicButton),
                ),
                IconButton(
                  tooltip: _editing ? l.doneEditing : l.editButtons,
                  isSelected: _editing,
                  icon: const Icon(Icons.edit_outlined),
                  selectedIcon: const Icon(Icons.check),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menu(v, profile, page),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'page-new',
                      child: Text(l.soundPageNew),
                    ),
                    PopupMenuItem(
                      value: 'page-rename',
                      child: Text(l.soundPageRename),
                    ),
                    PopupMenuItem(
                      enabled: profile.pages.length > 1,
                      value: 'page-delete',
                      child: Text(l.soundPageDelete),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'profile-new',
                      child: Text(l.soundProfileNew),
                    ),
                    PopupMenuItem(
                      value: 'profile-rename',
                      child: Text(l.soundProfileRename),
                    ),
                    PopupMenuItem(
                      enabled: board.items.length > 1,
                      value: 'profile-delete',
                      child: Text(l.soundProfileDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (profile.pages.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final p in profile.pages)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.folder_outlined, size: 18),
                        label: Text(p.name),
                        selected: p.id == page.id,
                        onSelected: (_) => setState(() => _pageId = p.id),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: page.pads.isEmpty
                ? EmptyState(icon: Icons.music_note, message: l.soundEmpty)
                : _grid(l, page, playing),
          ),
        ],
      ),
    );
  }

  Widget _grid(AppLocalizations l, SoundPage page, Set<String> playing) {
    final children = [
      for (final pad in page.pads)
        KeyedSubtree(
          key: ValueKey(pad.id),
          child: _padTile(l, pad, page.id, playing.contains(pad.inputName)),
        ),
    ];
    return ReorderableBuilder<SoundPad>(
      scrollController: _scroll,
      enableDraggable: _editing,
      onReorder: (reorder) => unawaited(
        ref
            .read(soundboardProvider.notifier)
            .reorderPads(page.id, reorder(page.pads)),
      ),
      builder: (children) => GridView(
        key: _gridKey,
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        children: children,
      ),
      children: children,
    );
  }

  Widget _padTile(
    AppLocalizations l,
    SoundPad pad,
    String pageId,
    bool playing,
  ) {
    final player = ref.read(soundPlayerProvider);
    final hold = pad.mode == SoundPlayMode.holdToPlay;
    return PadTile(
      label: pad.label,
      emoji: pad.emoji,
      icon: padIcon(pad.icon),
      color: Color(pad.color),
      active: playing,
      badge: l.badgePlaying,
      editing: _editing,
      onTap: _editing
          ? () => context.push('/sounds/pad/$pageId/${pad.id}')
          : hold
          ? null
          : () => _tap(pad, pageId, playing: playing),
      onTapDown: !_editing && hold
          ? () {
              tapFeedback(ref);
              unawaited(_run(() => player.start(pad), pad, pageId));
            }
          : null,
      onTapUp: !_editing && hold
          ? () => unawaited(_run(() => player.stop(pad), pad, pageId))
          : null,
      // Holding is how hold-to-play pads play, so no long-press menu there.
      onLongPress: _editing || hold
          ? null
          : () => _padMenu(pad, pageId, playing),
    );
  }
}
