import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/audio_math.dart';
import '../../domain/sound/sound_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../failure_text.dart';
import '../pad/pad_tile.dart';
import '../providers.dart';
import '../widgets/catalog.dart';
import '../widgets/name_picker.dart';
import 'soundboard_controller.dart';

/// Look and behaviour of one sound pad.
class SoundPadEditorPage extends ConsumerStatefulWidget {
  const SoundPadEditorPage({
    required this.pageId,
    required this.padId,
    super.key,
  });

  final String pageId;
  final String padId;

  @override
  ConsumerState<SoundPadEditorPage> createState() => _SoundPadEditorPageState();
}

class _SoundPadEditorPageState extends ConsumerState<SoundPadEditorPage> {
  SoundPad? _draft;
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(activeSoundboardProvider);
    _draft = profile.pages
        .where((p) => p.id == widget.pageId)
        .expand((p) => p.pads)
        .where((p) => p.id == widget.padId)
        .firstOrNull;
    _label = TextEditingController(text: _draft?.label);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _update(SoundPad Function(SoundPad) change) =>
      setState(() => _draft = change(_draft!));

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final label = _label.text.trim();
    final pad = _draft!.copyWith(
      label: label.isEmpty ? _draft!.inputName : label,
    );
    if (pad.inputName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.soundPickSource)));
      return;
    }
    await ref.read(soundboardProvider.notifier).upsertPad(widget.pageId, pad);
    if (!mounted) return;
    if (ref.read(isConnectedProvider)) {
      final ok = await runObs(
        context,
        () => ref.read(soundPlayerProvider).apply(pad),
      );
      if (!ok) return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = _draft;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.failNotFound)),
      );
    }
    final live = ref.watch(obsLiveStateProvider);
    final mediaInputs = live.inputs
        .where((i) => i.isMediaSource)
        .map((i) => i.name)
        .toList();
    final audioInputs = live.audioInputs
        .map((i) => i.name)
        .where((name) => name != draft.inputName)
        .toList();
    final ducking = draft.ducking;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.soundEdit),
        actions: [
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref
                  .read(soundboardProvider.notifier)
                  .deletePad(widget.pageId, draft.id);
              if (context.mounted) context.pop();
            },
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
                emoji: draft.emoji,
                icon: padIcon(draft.icon),
                color: Color(draft.color),
                active: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: l.fieldLabel,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          NamePickerField(
            label: l.soundSourceField,
            helper: l.soundSourceHelp,
            icon: Icons.audio_file_outlined,
            options: mediaInputs,
            value: draft.inputName,
            onChanged: (v) => _update((p) => p.copyWith(inputName: v)),
          ),
          const SizedBox(height: 20),
          Text(l.soundModeTitle, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<SoundPlayMode>(
            segments: [
              ButtonSegment(
                value: SoundPlayMode.playToEnd,
                icon: const Icon(Icons.touch_app_outlined),
                label: Text(l.soundModeToEnd),
              ),
              ButtonSegment(
                value: SoundPlayMode.holdToPlay,
                icon: const Icon(Icons.back_hand_outlined),
                label: Text(l.soundModeHold),
              ),
            ],
            selected: {draft.mode},
            onSelectionChanged: (v) =>
                _update((p) => p.copyWith(mode: v.first)),
          ),
          const SizedBox(height: 4),
          Text(
            draft.mode == SoundPlayMode.playToEnd
                ? l.soundModeToEndHelp
                : l.soundModeHoldHelp,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.soundLoop),
            subtitle: Text(l.soundLoopHelp),
            value: draft.loop,
            onChanged: (v) => _update((p) => p.copyWith(loop: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.soundVolume),
            subtitle: Text(
              draft.volumeMul == null
                  ? l.soundVolumeKeep
                  : formatDb(draft.volumeMul!),
            ),
            value: draft.volumeMul != null,
            onChanged: (v) =>
                _update((p) => p.copyWith(volumeMul: () => v ? 1.0 : null)),
          ),
          if (draft.volumeMul != null)
            Slider(
              value: mulToFader(draft.volumeMul!),
              label: formatDb(draft.volumeMul!),
              divisions: 50,
              onChanged: (v) =>
                  _update((p) => p.copyWith(volumeMul: () => faderToMul(v))),
            ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.duckingTitle),
            subtitle: Text(l.duckingHelp),
            value: ducking != null,
            onChanged: (v) => _update(
              (p) => p.copyWith(
                ducking: () => v
                    ? DuckingConfig(inputName: audioInputs.firstOrNull ?? '')
                    : null,
              ),
            ),
          ),
          if (ducking != null) ...[
            const SizedBox(height: 8),
            NamePickerField(
              label: l.duckingTarget,
              icon: Icons.mic_none,
              options: audioInputs,
              value: ducking.inputName,
              onChanged: (v) => _update(
                (p) => p.copyWith(
                  ducking: () => DuckingConfig(
                    inputName: v,
                    reductionDb: ducking.reductionDb,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.duckingAmount(ducking.reductionDb.round())),
            Slider(
              value: ducking.reductionDb.clamp(3, 40),
              min: 3,
              max: 40,
              divisions: 37,
              label: '-${ducking.reductionDb.round()} dB',
              onChanged: (v) => _update(
                (p) => p.copyWith(
                  ducking: () => DuckingConfig(
                    inputName: ducking.inputName,
                    reductionDb: v,
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          Text(l.fieldColor, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          ColorPickerRow(
            selected: draft.color,
            onSelected: (c) => _update((p) => p.copyWith(color: c)),
          ),
          const SizedBox(height: 20),
          Text(l.fieldEmoji, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text(l.noEmoji),
                selected: draft.emoji == null,
                onSelected: (_) =>
                    _update((p) => p.copyWith(emoji: () => null)),
              ),
              for (final emoji in soundEmojis)
                ChoiceChip(
                  label: Text(emoji, style: const TextStyle(fontSize: 20)),
                  selected: draft.emoji == emoji,
                  onSelected: (_) =>
                      _update((p) => p.copyWith(emoji: () => emoji)),
                ),
            ],
          ),
          if (draft.emoji == null) ...[
            const SizedBox(height: 20),
            Text(l.fieldIcon, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            IconPickerGrid(
              selected: draft.icon,
              onSelected: (i) => _update((p) => p.copyWith(icon: i)),
            ),
          ],
          const SizedBox(height: 96),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
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
