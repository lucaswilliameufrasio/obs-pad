import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/layout_store.dart';
import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../../domain/obs_repository.dart';
import '../../domain/pad/pad_models.dart';
import '../connection/obs_live_state.dart';
import '../l10n_util.dart';
import '../providers.dart';
import '../widgets/catalog.dart';

final padLayoutStoreProvider = Provider<PadLayoutStore>(
  (ref) => PadLayoutStore(ref.watch(sharedPreferencesProvider)),
);

class PadLayoutsNotifier extends Notifier<ProfileList<PadLayout>> {
  PadLayoutStore get _store => ref.read(padLayoutStoreProvider);

  @override
  ProfileList<PadLayout> build() {
    final stored = ref.watch(padLayoutStoreProvider).load();
    if (stored != null && stored.items.isNotEmpty) return stored;
    return _defaults();
  }

  ProfileList<PadLayout> _defaults() {
    final l = l10nOf(ref);
    PadButton button(
      String id,
      String label,
      String icon,
      int color,
      PadActionType type,
    ) => PadButton(
      id: id,
      label: label,
      icon: icon,
      color: color,
      action: PadAction(type: type),
    );
    final live = PadLayout(
      id: 'live',
      name: l.layoutLive,
      buttons: [
        button(
          'live-stream',
          l.actionToggleStream,
          'live',
          0xFFE53935,
          PadActionType.toggleStream,
        ),
        button(
          'live-record',
          l.actionToggleRecord,
          'record',
          0xFFD81B60,
          PadActionType.toggleRecord,
        ),
        button(
          'live-replay',
          l.actionSaveReplay,
          'replay',
          0xFF1E88E5,
          PadActionType.saveReplay,
        ),
      ],
    );
    final recording = PadLayout(
      id: 'recording',
      name: l.layoutRecording,
      buttons: [
        button(
          'rec-record',
          l.actionToggleRecord,
          'record',
          0xFFD81B60,
          PadActionType.toggleRecord,
        ),
        button(
          'rec-pause',
          l.actionToggleRecordPause,
          'pause',
          0xFFF9A825,
          PadActionType.toggleRecordPause,
        ),
      ],
    );
    final audio = PadLayout(id: 'audio', name: l.layoutAudioOnly, columns: 2);
    return ProfileList(items: [live, recording, audio], activeId: live.id);
  }

  PadLayout get active =>
      state.items.where((l) => l.id == state.activeId).firstOrNull ??
      state.items.first;

  Future<void> _save(List<PadLayout> items, {String? activeId}) async {
    state = ProfileList(items: items, activeId: activeId ?? state.activeId);
    await _store.save(state);
  }

  Future<void> _updateActive(PadLayout Function(PadLayout) change) {
    final current = active;
    return _save([
      for (final layout in state.items)
        layout.id == current.id ? change(layout) : layout,
    ]);
  }

  Future<void> setActive(String id) => _save(state.items, activeId: id);

  Future<void> addLayout(String name) {
    final layout = PadLayout(id: newId(), name: name);
    return _save([...state.items, layout], activeId: layout.id);
  }

  Future<void> renameActive(String name) =>
      _updateActive((l) => l.copyWith(name: name));

  Future<void> setColumns(int columns) =>
      _updateActive((l) => l.copyWith(columns: columns.clamp(2, 6)));

  Future<void> deleteActive() async {
    if (state.items.length <= 1) return;
    final id = active.id;
    final items = state.items.where((l) => l.id != id).toList();
    await _save(items, activeId: items.first.id);
  }

  Future<void> upsertButton(PadButton button) => _updateActive((layout) {
    final buttons = [...layout.buttons];
    final index = buttons.indexWhere((b) => b.id == button.id);
    if (index >= 0) {
      buttons[index] = button;
    } else {
      buttons.add(button);
    }
    return layout.copyWith(buttons: buttons);
  });

  Future<void> deleteButton(String id) => _updateActive(
    (l) => l.copyWith(buttons: l.buttons.where((b) => b.id != id).toList()),
  );

  Future<void> reorder(List<PadButton> buttons) =>
      _updateActive((l) => l.copyWith(buttons: buttons));

  /// "Criar botões automaticamente": one button per scene.
  Future<int> addSceneButtons(List<ObsScene> scenes) {
    final existing = active.buttons
        .where((b) => b.action.type == PadActionType.switchScene)
        .map((b) => b.action.sceneName)
        .toSet();
    final added = [
      for (final (i, scene) in scenes.indexed)
        if (!existing.contains(scene.name))
          PadButton(
            id: newId() + i.toString(),
            label: scene.name,
            icon: 'videocam',
            color: padColors[i % padColors.length],
            action: PadAction(
              type: PadActionType.switchScene,
              sceneName: scene.name,
            ),
          ),
    ];
    return _updateActive((l) => l.copyWith(buttons: [...l.buttons, ...added]))
        .then((_) => added.length);
  }

  /// One mute button per audio input.
  Future<int> addMuteButtons(List<ObsAudioInput> inputs) {
    final existing = active.buttons
        .where((b) => b.action.type == PadActionType.toggleMute)
        .map((b) => b.action.inputName)
        .toSet();
    final added = [
      for (final (i, input) in inputs.indexed)
        if (!existing.contains(input.name))
          PadButton(
            id: newId() + i.toString(),
            label: input.name,
            icon: 'mic',
            color: 0xFF00897B,
            action: PadAction(
              type: PadActionType.toggleMute,
              inputName: input.name,
            ),
          ),
    ];
    return _updateActive((l) => l.copyWith(buttons: [...l.buttons, ...added]))
        .then((_) => added.length);
  }
}

final padLayoutsProvider =
    NotifierProvider<PadLayoutsNotifier, ProfileList<PadLayout>>(
      PadLayoutsNotifier.new,
    );

final activePadLayoutProvider = Provider<PadLayout>((ref) {
  ref.watch(padLayoutsProvider);
  return ref.read(padLayoutsProvider.notifier).active;
});

// -----------------------------------------------------------------------------
// Running actions
// -----------------------------------------------------------------------------

/// Is the button "on"? Mirrors OBS state so it lights up correctly even when
/// the change happened in OBS itself.
bool? isActionActive(PadAction action, ObsLiveState live) =>
    switch (action.type) {
      PadActionType.switchScene => live.currentScene == action.sceneName,
      PadActionType.toggleSource => _sourceEnabled(action, live),
      PadActionType.toggleMute => live.isMuted(action.inputName ?? ''),
      PadActionType.toggleStream ||
      PadActionType.startStream ||
      PadActionType.stopStream => live.streamActive,
      PadActionType.toggleRecord ||
      PadActionType.startRecord ||
      PadActionType.stopRecord => live.recordActive,
      PadActionType.toggleRecordPause => live.recordPaused,
      PadActionType.saveReplay => live.replayActive,
      PadActionType.hotkey || PadActionType.macro => null,
    };

bool? _sourceEnabled(PadAction action, ObsLiveState live) => live
    .sceneItems[action.sceneName]
    ?.where((item) => item.sourceName == action.sourceName)
    .firstOrNull
    ?.enabled;

/// Would running this action stop the live? Used to ask for confirmation.
bool stopsStream(PadAction action, ObsLiveState live) => switch (action.type) {
  PadActionType.stopStream => true,
  PadActionType.toggleStream => live.streamActive,
  PadActionType.macro => action.steps.any((s) => stopsStream(s.action, live)),
  _ => false,
};

class PadActionRunner {
  PadActionRunner(this._repo, this._live);

  final ObsRepository _repo;
  final ObsLiveState Function() _live;

  Future<void> run(PadAction action) async {
    switch (action.type) {
      case PadActionType.switchScene:
        await _repo.setCurrentProgramScene(action.sceneName ?? '');
      case PadActionType.toggleSource:
        await _toggleSource(action.sceneName ?? '', action.sourceName ?? '');
      case PadActionType.toggleMute:
        await _repo.toggleInputMute(action.inputName ?? '');
      case PadActionType.toggleStream:
        await _repo.toggleStream();
      case PadActionType.startStream:
        await _repo.startStream();
      case PadActionType.stopStream:
        await _repo.stopStream();
      case PadActionType.toggleRecord:
        await _repo.toggleRecord();
      case PadActionType.startRecord:
        await _repo.startRecord();
      case PadActionType.stopRecord:
        await _repo.stopRecord();
      case PadActionType.toggleRecordPause:
        await _repo.toggleRecordPause();
      case PadActionType.saveReplay:
        await _repo.saveReplayBuffer();
      case PadActionType.hotkey:
        await _repo.triggerHotkey(action.hotkeyName ?? '');
      case PadActionType.macro:
        for (final step in action.steps) {
          // Macros cannot contain macros (no accidental infinite loops).
          if (step.action.type != PadActionType.macro) {
            await run(step.action);
          }
          if (step.delayMs > 0) {
            await Future<void>.delayed(Duration(milliseconds: step.delayMs));
          }
        }
    }
  }

  Future<void> _toggleSource(String sceneName, String sourceName) async {
    var items = _live().sceneItems[sceneName];
    items ??= await _repo.getSceneItems(sceneName);
    final item = items.where((i) => i.sourceName == sourceName).firstOrNull;
    if (item == null) {
      throw ObsFailure(ObsFailureKind.resourceNotFound, resource: sourceName);
    }
    await _repo.setSceneItemEnabled(sceneName, item.id, enabled: !item.enabled);
  }
}

final padActionRunnerProvider = Provider<PadActionRunner>(
  (ref) => PadActionRunner(
    ref.watch(obsRepositoryProvider),
    () => ref.read(obsLiveStateProvider),
  ),
);
