import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../../domain/sound/sound_models.dart';
import '../../l10n/app_localizations.dart';
import '../connection/obs_live_state.dart';
import '../providers.dart';
import '../widgets/catalog.dart';
import '../widgets/common.dart';
import '../widgets/name_picker.dart';
import 'soundboard_controller.dart';

enum _Mode { newFile, existing }

/// "Adicionar som": the audio file stays on the PC. The app creates (or
/// updates) a Media Source in OBS pointing to that file, then adds a pad.
class AddSoundPage extends ConsumerStatefulWidget {
  const AddSoundPage({required this.pageId, super.key});

  final String pageId;

  @override
  ConsumerState<AddSoundPage> createState() => _AddSoundPageState();
}

class _AddSoundPageState extends ConsumerState<AddSoundPage> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _path = TextEditingController();
  final _inputName = TextEditingController();
  bool _inputNameTouched = false;
  _Mode _mode = _Mode.newFile;
  String? _scene;
  String? _existingInput;
  bool _allScenes = true;
  bool _monitor = true;
  bool _loop = false;
  bool _busy = false;
  ObsFailure? _failure;

  @override
  void dispose() {
    _label.dispose();
    _path.dispose();
    _inputName.dispose();
    super.dispose();
  }

  void _onLabelChanged(String value) {
    if (!_inputNameTouched) {
      final l = AppLocalizations.of(context);
      _inputName.text = value.trim().isEmpty
          ? ''
          : l.soundInputNameDefault(value.trim());
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final live = ref.read(obsLiveStateProvider);
    final label = _label.text.trim();

    String inputName;
    if (_mode == _Mode.existing) {
      inputName = _existingInput ?? '';
    } else {
      inputName = _inputName.text.trim().isEmpty
          ? l.soundInputNameDefault(label)
          : _inputName.text.trim();
      final scene =
          _scene ?? live.currentScene ?? live.scenes.firstOrNull?.name;
      if (scene == null) return;
      setState(() {
        _busy = true;
        _failure = null;
      });
      try {
        await ref
            .read(obsRepositoryProvider)
            .setupMediaSource(
              MediaSourceRequest(
                inputName: inputName,
                filePath: _path.text.trim(),
                sceneName: scene,
                alsoAddToScenes: _allScenes
                    ? live.scenes.map((s) => s.name).toList()
                    : const [],
                loop: _loop,
                monitor: _monitor,
              ),
            );
      } on ObsFailure catch (failure) {
        if (mounted) {
          setState(() {
            _busy = false;
            _failure = failure;
          });
        }
        return;
      }
    }

    final index = ref.read(activeSoundboardProvider).allPads.length;
    final pad = SoundPad(
      id: newId(),
      label: label.isEmpty ? inputName : label,
      inputName: inputName,
      emoji: '🔊',
      color: padColors[(index + 7) % padColors.length],
      loop: _loop,
    );
    await ref.read(soundboardProvider.notifier).upsertPad(widget.pageId, pad);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.soundAdded(pad.label))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = ref.watch(obsLiveStateProvider);
    final connected = ref.watch(isConnectedProvider);
    final sceneNames = live.scenes.map((s) => s.name).toList();
    final mediaInputs = live.inputs
        .where((i) => i.isMediaSource)
        .map((i) => i.name)
        .toList();
    final scene = _scene ?? live.currentScene ?? sceneNames.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.soundAdd)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HintCard(text: l.soundAddIntro, icon: Icons.computer),
            const SizedBox(height: 12),
            if (!connected) ...[
              HintCard(
                warning: true,
                icon: Icons.link_off,
                text: l.soundAddNeedsConnection,
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<_Mode>(
              segments: [
                ButtonSegment(
                  value: _Mode.newFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l.soundFromFile),
                ),
                ButtonSegment(
                  value: _Mode.existing,
                  icon: const Icon(Icons.library_music_outlined),
                  label: Text(l.soundFromExisting),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() {
                _mode = v.first;
                _failure = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('field-sound-label'),
              controller: _label,
              decoration: InputDecoration(
                labelText: l.fieldLabel,
                hintText: l.soundLabelHint,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              onChanged: _onLabelChanged,
              validator: (v) =>
                  _mode == _Mode.newFile && (v?.trim().isEmpty ?? true)
                  ? l.errNameEmpty
                  : null,
            ),
            const SizedBox(height: 12),
            if (_mode == _Mode.newFile) ...[
              TextFormField(
                key: const Key('field-sound-path'),
                controller: _path,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l.soundPathField,
                  hintText: r'C:\Users\Ana\Music\aplausos.mp3',
                  helperText: l.soundPathHelp,
                  helperMaxLines: 4,
                  prefixIcon: const Icon(Icons.folder_open),
                ),
                validator: (v) {
                  final path = v?.trim() ?? '';
                  if (path.isEmpty) return l.soundPathEmpty;
                  if (!path.contains('/') && !path.contains(r'\')) {
                    return l.soundPathInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              NamePickerField(
                label: l.fieldScene,
                icon: Icons.videocam_outlined,
                options: sceneNames,
                value: scene,
                onChanged: (v) => setState(() => _scene = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.soundAllScenes),
                subtitle: Text(l.soundAllScenesHelp),
                value: _allScenes,
                onChanged: (v) => setState(() => _allScenes = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.soundMonitor),
                subtitle: Text(l.soundMonitorHelp),
                value: _monitor,
                onChanged: (v) => setState(() => _monitor = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.soundLoop),
                value: _loop,
                onChanged: (v) => setState(() => _loop = v),
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.advanced),
                children: [
                  TextFormField(
                    controller: _inputName,
                    decoration: InputDecoration(
                      labelText: l.soundInputNameField,
                      helperText: l.soundInputNameHelp,
                      helperMaxLines: 3,
                    ),
                    onChanged: (_) => _inputNameTouched = true,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ] else ...[
              NamePickerField(
                label: l.soundSourceField,
                helper: mediaInputs.isEmpty ? l.soundNoMediaSources : null,
                icon: Icons.audio_file_outlined,
                options: mediaInputs,
                value: _existingInput,
                onChanged: (v) => setState(() => _existingInput = v),
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 16),
              FailureCard(failure: _failure!),
              const SizedBox(height: 8),
              const _ManualSteps(),
            ],
            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const Key('btn-add-sound'),
            onPressed:
                _busy ||
                    (_mode == _Mode.newFile && !connected) ||
                    (_mode == _Mode.existing &&
                        (_existingInput?.isEmpty ?? true))
                ? null
                : _submit,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(
              _mode == _Mode.newFile ? l.soundCreateInObs : l.soundAddPad,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the automatic setup fails: how to do it by hand in OBS.
class _ManualSteps extends StatelessWidget {
  const _ManualSteps();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.manualTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            NumberedStep(number: 1, text: l.manualStep1),
            NumberedStep(number: 2, text: l.manualStep2),
            NumberedStep(number: 3, text: l.manualStep3),
            NumberedStep(number: 4, text: l.manualStep4),
            NumberedStep(number: 5, text: l.manualStep5),
            NumberedStep(number: 6, text: l.manualStep6),
          ],
        ),
      ),
    );
  }
}
