import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pad/pad_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../providers.dart';
import '../widgets/name_picker.dart';
import 'pad_action_text.dart';

/// Edits what a button does: type + the scene/source/input/hotkey it needs,
/// or the list of steps of a macro.
class ActionEditor extends ConsumerWidget {
  const ActionEditor({
    required this.action,
    required this.onChanged,
    this.allowMacro = true,
    super.key,
  });

  final PadAction action;
  final ValueChanged<PadAction> onChanged;
  final bool allowMacro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final live = ref.watch(obsLiveStateProvider);
    final types = PadActionType.values.where(
      (t) => allowMacro || t != PadActionType.macro,
    );

    PadAction withType(PadActionType type) => PadAction(
      type: type,
      sceneName: type.needsScene ? action.sceneName : null,
      sourceName: type.needsSource ? action.sourceName : null,
      inputName: type.needsInput ? action.inputName : null,
      hotkeyName: type.needsHotkey ? action.hotkeyName : null,
      steps: type == PadActionType.macro ? action.steps : const [],
    );

    final sceneNames = live.scenes.map((s) => s.name).toList();
    final sourceNames = (live.sceneItems[action.sceneName] ?? const [])
        .map((i) => i.sourceName)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropdownButtonFormField<PadActionType>(
          initialValue: action.type,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.fieldAction,
            prefixIcon: const Icon(Icons.touch_app_outlined),
          ),
          items: [
            for (final type in types)
              DropdownMenuItem(
                value: type,
                child: Text(actionTypeLabel(l, type)),
              ),
          ],
          onChanged: (type) {
            if (type != null) onChanged(withType(type));
          },
        ),
        if (action.type.needsScene)
          NamePickerField(
            label: l.fieldScene,
            icon: Icons.videocam_outlined,
            options: sceneNames,
            value: action.sceneName,
            onChanged: (v) => onChanged(
              PadAction(
                type: action.type,
                sceneName: v,
                sourceName: v == action.sceneName ? action.sourceName : null,
              ),
            ),
          ),
        if (action.type.needsSource)
          NamePickerField(
            label: l.fieldSource,
            icon: Icons.layers_outlined,
            options: sourceNames,
            value: action.sourceName,
            onChanged: (v) => onChanged(
              PadAction(
                type: action.type,
                sceneName: action.sceneName,
                sourceName: v,
              ),
            ),
          ),
        if (action.type.needsInput)
          NamePickerField(
            label: l.fieldAudioInput,
            icon: Icons.mic_none,
            options: live.audioInputs.map((i) => i.name).toList(),
            value: action.inputName,
            onChanged: (v) =>
                onChanged(PadAction(type: action.type, inputName: v)),
          ),
        if (action.type.needsHotkey)
          _HotkeyField(action: action, onChanged: onChanged),
        if (action.type == PadActionType.macro)
          _MacroEditor(action: action, onChanged: onChanged),
      ],
    );
  }
}

class _HotkeyField extends ConsumerWidget {
  const _HotkeyField({required this.action, required this.onChanged});

  final PadAction action;
  final ValueChanged<PadAction> onChanged;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    List<String> hotkeys = const [];
    final ok = await runObs(context, () async {
      hotkeys = await ref.read(obsRepositoryProvider).getHotkeys();
    });
    if (!ok || !context.mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _HotkeyList(hotkeys: hotkeys),
    );
    if (picked != null) {
      onChanged(PadAction(type: PadActionType.hotkey, hotkeyName: picked));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('hotkey-${action.hotkeyName}'),
          initialValue: action.hotkeyName,
          decoration: InputDecoration(
            labelText: l.fieldHotkey,
            helperText: l.fieldHotkeyHelp,
            helperMaxLines: 3,
            prefixIcon: const Icon(Icons.keyboard_outlined),
          ),
          onChanged: (v) => onChanged(
            PadAction(type: PadActionType.hotkey, hotkeyName: v.trim()),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: ref.watch(isConnectedProvider)
                ? () => _pick(context, ref)
                : null,
            icon: const Icon(Icons.list),
            label: Text(l.pickFromObs),
          ),
        ),
      ],
    );
  }
}

class _HotkeyList extends StatefulWidget {
  const _HotkeyList({required this.hotkeys});

  final List<String> hotkeys;

  @override
  State<_HotkeyList> createState() => _HotkeyListState();
}

class _HotkeyListState extends State<_HotkeyList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = widget.hotkeys
        .where((h) => h.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.search,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(filtered[i]),
                onTap: () => Navigator.pop(context, filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroEditor extends StatelessWidget {
  const _MacroEditor({required this.action, required this.onChanged});

  final PadAction action;
  final ValueChanged<PadAction> onChanged;

  void _setSteps(List<MacroStep> steps) =>
      onChanged(PadAction(type: PadActionType.macro, steps: steps));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final steps = action.steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.macroHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final (index, step) in steps.indexed)
          Card(
            key: ValueKey('step-$index-${steps.length}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        l.macroStep(index + 1),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l.moveUp,
                        onPressed: index == 0
                            ? null
                            : () => _setSteps(
                                [...steps]
                                  ..removeAt(index)
                                  ..insert(index - 1, step),
                              ),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: l.delete,
                        onPressed: () => _setSteps([...steps]..removeAt(index)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionEditor(
                      action: step.action,
                      allowMacro: false,
                      onChanged: (a) => _setSteps([
                        for (final (i, s) in steps.indexed)
                          i == index ? s.copyWith(action: a) : s,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.hourglass_empty, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.macroDelay(
                            (step.delayMs / 1000).toStringAsFixed(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: step.delayMs.clamp(0, 10000).toDouble(),
                    max: 10000,
                    divisions: 40,
                    label: '${(step.delayMs / 1000).toStringAsFixed(2)} s',
                    onChanged: (v) => _setSteps([
                      for (final (i, s) in steps.indexed)
                        i == index ? s.copyWith(delayMs: v.round()) : s,
                    ]),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _setSteps([
            ...steps,
            const MacroStep(
              action: PadAction(type: PadActionType.switchScene),
              delayMs: 500,
            ),
          ]),
          icon: const Icon(Icons.add),
          label: Text(l.macroAddStep),
        ),
      ],
    );
  }
}
