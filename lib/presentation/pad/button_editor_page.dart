import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/pad/pad_models.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';
import '../widgets/catalog.dart';
import 'action_editor.dart';
import 'pad_action_text.dart';
import 'pad_controller.dart';
import 'pad_tile.dart';

/// Create or edit one button of the active layout.
class ButtonEditorPage extends ConsumerStatefulWidget {
  const ButtonEditorPage({required this.buttonId, super.key});

  /// 'new' to create.
  final String buttonId;

  @override
  ConsumerState<ButtonEditorPage> createState() => _ButtonEditorPageState();
}

class _ButtonEditorPageState extends ConsumerState<ButtonEditorPage> {
  late PadButton _draft;
  late bool _isNew;
  late final TextEditingController _label;
  bool _labelTouched = false;

  @override
  void initState() {
    super.initState();
    final layout = ref.read(activePadLayoutProvider);
    final existing = layout.buttons
        .where((b) => b.id == widget.buttonId)
        .firstOrNull;
    _isNew = existing == null;
    _draft =
        existing ??
        PadButton(
          id: newId(),
          label: '',
          icon: 'videocam',
          color: padColors[layout.buttons.length % padColors.length],
          action: const PadAction(type: PadActionType.switchScene),
        );
    _label = TextEditingController(text: _draft.label);
    _labelTouched = !_isNew;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  /// Until the user types a label, suggest one from the action.
  void _setAction(PadAction action) {
    final l = AppLocalizations.of(context);
    setState(() {
      _draft = _draft.copyWith(action: action, icon: _suggestIcon(action));
      if (!_labelTouched) {
        _label.text = switch (action.type) {
          PadActionType.switchScene => action.sceneName ?? '',
          PadActionType.toggleSource => action.sourceName ?? '',
          PadActionType.toggleMute => action.inputName ?? '',
          PadActionType.hotkey => action.hotkeyName ?? '',
          _ => actionTypeLabel(l, action.type),
        };
      }
    });
  }

  String _suggestIcon(PadAction action) {
    if (!_isNew) return _draft.icon;
    return switch (action.type) {
      PadActionType.switchScene => 'videocam',
      PadActionType.toggleSource => 'visibility',
      PadActionType.toggleMute => 'mic',
      PadActionType.toggleStream ||
      PadActionType.startStream ||
      PadActionType.stopStream => 'live',
      PadActionType.toggleRecord ||
      PadActionType.startRecord ||
      PadActionType.stopRecord => 'record',
      PadActionType.toggleRecordPause => 'pause',
      PadActionType.saveReplay => 'replay',
      PadActionType.hotkey => 'keyboard',
      PadActionType.macro => 'auto',
    };
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final label = _label.text.trim();
    final button = _draft.copyWith(
      label: label.isEmpty ? actionTypeLabel(l, _draft.action.type) : label,
    );
    if (!button.action.isComplete) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.buttonIncomplete)));
      return;
    }
    await ref.read(padLayoutsProvider.notifier).upsertButton(button);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(padLayoutsProvider.notifier).deleteButton(_draft.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.addButton : l.editButton),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox.square(
              dimension: 120,
              child: PadTile(
                label: _label.text.isEmpty ? '…' : _label.text,
                icon: padIcon(_draft.icon),
                color: Color(_draft.color),
                scale: _draft.size.scale,
                active: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionEditor(action: _draft.action, onChanged: _setAction),
          const SizedBox(height: 16),
          TextField(
            key: const Key('field-label'),
            controller: _label,
            decoration: InputDecoration(
              labelText: l.fieldLabel,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            onChanged: (_) => setState(() => _labelTouched = true),
          ),
          const SizedBox(height: 20),
          Text(l.fieldSize, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<PadButtonSize>(
            segments: [
              ButtonSegment(
                value: PadButtonSize.small,
                label: Text(l.sizeSmall),
              ),
              ButtonSegment(
                value: PadButtonSize.medium,
                label: Text(l.sizeMedium),
              ),
              ButtonSegment(
                value: PadButtonSize.large,
                label: Text(l.sizeLarge),
              ),
            ],
            selected: {_draft.size},
            onSelectionChanged: (s) =>
                setState(() => _draft = _draft.copyWith(size: s.first)),
          ),
          const SizedBox(height: 20),
          Text(l.fieldColor, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ColorPickerRow(
            selected: _draft.color,
            onSelected: (c) =>
                setState(() => _draft = _draft.copyWith(color: c)),
          ),
          const SizedBox(height: 20),
          Text(l.fieldIcon, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          IconPickerGrid(
            selected: _draft.icon,
            onSelected: (i) =>
                setState(() => _draft = _draft.copyWith(icon: i)),
          ),
          const SizedBox(height: 96),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const Key('btn-save-button'),
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(l.save),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}
