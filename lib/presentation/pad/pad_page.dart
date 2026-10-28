import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/pad/pad_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../providers.dart';
import '../scenes/scene_switcher.dart';
import '../widgets/catalog.dart';
import '../widgets/common.dart';
import 'pad_action_text.dart';
import 'pad_controller.dart';
import 'pad_tile.dart';

/// Scene strip + the customizable button grid of the active layout.
class PadPage extends ConsumerStatefulWidget {
  const PadPage({super.key});

  @override
  ConsumerState<PadPage> createState() => _PadPageState();
}

class _PadPageState extends ConsumerState<PadPage> {
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();
  final _running = <String>{};
  bool _editing = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _press(PadButton button) async {
    if (_running.contains(button.id)) return;
    final l = AppLocalizations.of(context);
    final live = ref.read(obsLiveStateProvider);
    if (!button.action.isComplete) {
      _snack(l.buttonIncomplete);
      return;
    }
    if (stopsStream(button.action, live)) {
      final ok = await _confirm(l.confirmStopLiveTitle, l.confirmStopLiveBody);
      if (!ok || !mounted) return;
    }
    tapFeedback(ref);
    setState(() => _running.add(button.id));
    await runObs(
      context,
      () => ref.read(padActionRunnerProvider).run(button.action),
    );
    if (mounted) setState(() => _running.remove(button.id));
  }

  Future<bool> _confirm(String title, String body) async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _buttonMenu(PadButton button) async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(button.label),
              subtitle: Text(describeAction(l, button.action)),
            ),
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
    if (!mounted) return;
    if (choice == 'edit') {
      await context.push('/pad/button/${button.id}');
    } else if (choice == 'delete') {
      await ref.read(padLayoutsProvider.notifier).deleteButton(button.id);
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

  Future<void> _layoutMenu(String value) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(padLayoutsProvider.notifier);
    final live = ref.read(obsLiveStateProvider);
    switch (value) {
      case 'new':
        final name = await _askName(l.layoutNew);
        if (name != null && name.isNotEmpty) await notifier.addLayout(name);
      case 'rename':
        final name = await _askName(l.layoutRename, notifier.active.name);
        if (name != null && name.isNotEmpty) await notifier.renameActive(name);
      case 'delete':
        final ok = await _confirm(
          l.layoutDeleteConfirm(notifier.active.name),
          l.layoutDeleteBody,
        );
        if (ok) await notifier.deleteActive();
      case 'scenes':
        final count = await notifier.addSceneButtons(live.scenes);
        if (mounted) _snack(l.buttonsAdded(count));
      case 'audio':
        final count = await notifier.addMuteButtons(live.audioInputs);
        if (mounted) _snack(l.buttonsAdded(count));
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final layouts = ref.watch(padLayoutsProvider);
    final layout = ref.watch(activePadLayoutProvider);
    final live = ref.watch(obsLiveStateProvider);
    final connected = ref.watch(isConnectedProvider);

    return Scaffold(
      floatingActionButton: _editing
          ? FloatingActionButton.extended(
              heroTag: 'add-button',
              onPressed: () => context.push('/pad/button/new'),
              icon: const Icon(Icons.add),
              label: Text(l.addButton),
            )
          : null,
      body: Column(
        children: [
          const SceneStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        for (final item in layouts.items)
                          ButtonSegment(value: item.id, label: Text(item.name)),
                      ],
                      selected: {layout.id},
                      onSelectionChanged: (ids) => ref
                          .read(padLayoutsProvider.notifier)
                          .setActive(ids.first),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('btn-edit-pad'),
                  tooltip: _editing ? l.doneEditing : l.editButtons,
                  isSelected: _editing,
                  icon: const Icon(Icons.edit_outlined),
                  selectedIcon: const Icon(Icons.check),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
                PopupMenuButton<String>(
                  tooltip: l.layoutMenu,
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  onSelected: _layoutMenu,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'new', child: Text(l.layoutNew)),
                    PopupMenuItem(value: 'rename', child: Text(l.layoutRename)),
                    PopupMenuItem(
                      enabled: connected && live.scenes.isNotEmpty,
                      value: 'scenes',
                      child: Text(l.layoutAddSceneButtons),
                    ),
                    PopupMenuItem(
                      enabled: connected && live.audioInputs.isNotEmpty,
                      value: 'audio',
                      child: Text(l.layoutAddMuteButtons),
                    ),
                    PopupMenuItem(
                      enabled: layouts.items.length > 1,
                      value: 'delete',
                      child: Text(l.layoutDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(child: Text(l.editModeHint)),
                  Text(l.columns),
                  IconButton(
                    tooltip: '-',
                    onPressed: layout.columns > 2
                        ? () => ref
                              .read(padLayoutsProvider.notifier)
                              .setColumns(layout.columns - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${layout.columns}'),
                  IconButton(
                    tooltip: '+',
                    onPressed: layout.columns < 6
                        ? () => ref
                              .read(padLayoutsProvider.notifier)
                              .setColumns(layout.columns + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          Expanded(
            child: layout.buttons.isEmpty
                ? EmptyState(
                    icon: Icons.grid_view,
                    message: l.padEmpty,
                    action: FilledButton.icon(
                      onPressed: () => context.push('/pad/button/new'),
                      icon: const Icon(Icons.add),
                      label: Text(l.addButton),
                    ),
                  )
                : _grid(context, l, layout, live),
          ),
        ],
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    AppLocalizations l,
    PadLayout layout,
    ObsLiveState live,
  ) {
    final children = [
      for (final button in layout.buttons)
        KeyedSubtree(key: ValueKey(button.id), child: _tile(l, button, live)),
    ];
    return ReorderableBuilder<PadButton>(
      scrollController: _scroll,
      enableDraggable: _editing,
      onReorder: (reorder) => unawaited(
        ref.read(padLayoutsProvider.notifier).reorder(reorder(layout.buttons)),
      ),
      builder: (children) => GridView(
        key: _gridKey,
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        children: children,
      ),
      children: children,
    );
  }

  Widget _tile(AppLocalizations l, PadButton button, ObsLiveState live) {
    final active = isActionActive(button.action, live) ?? false;
    return PadTile(
      label: button.label,
      icon: padIcon(button.icon),
      color: Color(button.color),
      active: active,
      badge: activeBadge(l, button.action.type),
      busy: _running.contains(button.id),
      scale: button.size.scale,
      editing: _editing,
      onTap: _editing
          ? () => context.push('/pad/button/${button.id}')
          : () => _press(button),
      onLongPress: _editing ? null : () => _buttonMenu(button),
    );
  }
}
