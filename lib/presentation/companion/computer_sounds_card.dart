import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import '../../l10n/app_localizations.dart';
import 'computer_helper.dart';

/// In "Adicionar som": with OBS Pad Desktop open on the computer, send a
/// sound from the phone or pick one from the computer's sounds folder,
/// instead of typing the path.
class ComputerSoundsCard extends ConsumerStatefulWidget {
  const ComputerSoundsCard({required this.onPicked, super.key});

  /// A sound now on the computer, with its path there.
  final void Function(SoundFile sound) onPicked;

  @override
  ConsumerState<ComputerSoundsCard> createState() => _ComputerSoundsCardState();
}

class _ComputerSoundsCardState extends ConsumerState<ComputerSoundsCard> {
  bool _busy = false;
  String? _error;

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Exception catch (error) {
      if (mounted) {
        setState(
          () => _error = describeCompanionError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendFromPhone(ComputerHelper helper) => _guard(() async {
    final picked = await ref.read(soundFilePickerProvider)();
    if (picked == null) return;
    final saved = await helper.uploadSound(picked.name, picked.bytes);
    widget.onPicked(saved);
  });

  Future<void> _pickFromComputer(ComputerHelper helper) async {
    ({String folder, List<SoundFile> sounds})? listing;
    await _guard(() async => listing = await helper.listSounds());
    final loaded = listing;
    if (loaded == null || !mounted) return;
    final chosen = await showModalBottomSheet<SoundFile>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _ComputerFolderSheet(folder: loaded.folder, sounds: loaded.sounds),
    );
    if (chosen != null) widget.onPicked(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final helper = ref.watch(computerHelperProvider);
    final scheme = Theme.of(context).colorScheme;
    return switch (helper) {
      AsyncData(value: final ComputerHelper helper) => Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.companionReady),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('btn-send-from-phone'),
                    onPressed: _busy ? null : () => _sendFromPhone(helper),
                    icon: const Icon(Icons.phone_android),
                    label: Text(l.companionSendFromPhone),
                  ),
                  OutlinedButton.icon(
                    key: const Key('btn-pick-from-computer'),
                    onPressed: _busy ? null : () => _pickFromComputer(helper),
                    icon: const Icon(Icons.folder_open),
                    label: Text(l.companionPickFromComputer),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const Key('companion-error'),
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      AsyncLoading() => const SizedBox.shrink(),
      // Not running (or not reachable): the manual path still works.
      _ => Text(
        l.companionTip,
        key: const Key('companion-tip'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    };
  }
}

class _ComputerFolderSheet extends StatelessWidget {
  const _ComputerFolderSheet({required this.folder, required this.sounds});

  final String folder;
  final List<SoundFile> sounds;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l.companionFolderTitle(folder),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          if (sounds.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l.companionFolderEmpty),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final sound in sounds)
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(sound.name),
                      subtitle: Text(_size(sound.sizeBytes)),
                      onTap: () => Navigator.of(context).pop(sound),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _size(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';
}
