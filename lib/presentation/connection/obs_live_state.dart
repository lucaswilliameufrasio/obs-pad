import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/obs_events.dart';
import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../providers.dart';

/// Mirror of the OBS state the buttons care about, kept in sync by events.
class ObsLiveState {
  const ObsLiveState({
    this.loaded = false,
    this.scenes = const [],
    this.currentScene,
    this.sceneItems = const {},
    this.inputs = const [],
    this.audioInputs = const [],
    this.streamActive = false,
    this.streamReconnecting = false,
    this.recordActive = false,
    this.recordPaused = false,
    this.replayActive = false,
    this.playingMedia = const {},
  });

  final bool loaded;
  final List<ObsScene> scenes;
  final String? currentScene;

  /// Scene name -> items of that scene.
  final Map<String, List<ObsSceneItem>> sceneItems;
  final List<ObsInput> inputs;
  final List<ObsAudioInput> audioInputs;
  final bool streamActive;
  final bool streamReconnecting;
  final bool recordActive;
  final bool recordPaused;
  final bool replayActive;
  final Set<String> playingMedia;

  bool? isMuted(String inputName) =>
      audioInputs.where((i) => i.name == inputName).firstOrNull?.muted;

  bool? isSceneItemEnabled(String sceneName, int itemId) =>
      sceneItems[sceneName]
          ?.where((item) => item.id == itemId)
          .firstOrNull
          ?.enabled;

  ObsLiveState copyWith({
    bool? loaded,
    List<ObsScene>? scenes,
    String? currentScene,
    Map<String, List<ObsSceneItem>>? sceneItems,
    List<ObsInput>? inputs,
    List<ObsAudioInput>? audioInputs,
    bool? streamActive,
    bool? streamReconnecting,
    bool? recordActive,
    bool? recordPaused,
    bool? replayActive,
    Set<String>? playingMedia,
  }) => ObsLiveState(
    loaded: loaded ?? this.loaded,
    scenes: scenes ?? this.scenes,
    currentScene: currentScene ?? this.currentScene,
    sceneItems: sceneItems ?? this.sceneItems,
    inputs: inputs ?? this.inputs,
    audioInputs: audioInputs ?? this.audioInputs,
    streamActive: streamActive ?? this.streamActive,
    streamReconnecting: streamReconnecting ?? this.streamReconnecting,
    recordActive: recordActive ?? this.recordActive,
    recordPaused: recordPaused ?? this.recordPaused,
    replayActive: replayActive ?? this.replayActive,
    playingMedia: playingMedia ?? this.playingMedia,
  );
}

class ObsLiveStateNotifier extends Notifier<ObsLiveState> {
  @override
  ObsLiveState build() {
    final connected = ref.watch(isConnectedProvider);
    if (!connected) return const ObsLiveState();

    final sub = ref.watch(obsEventsProvider).listen(_onEvent);
    ref.onDispose(sub.cancel);
    unawaited(refresh());
    return const ObsLiveState();
  }

  Future<void> refresh() async {
    final repo = ref.read(obsRepositoryProvider);
    try {
      final results = await (
        repo.getScenes(),
        repo.getCurrentProgramScene(),
        repo.getInputs(),
        repo.getAudioInputs(),
        repo.getStreamStatus(),
        repo.getRecordStatus(),
        repo.getReplayBufferActive(),
      ).wait;
      final (scenes, current, inputs, audio, stream, record, replay) = results;
      final items = await _loadSceneItems(scenes.map((s) => s.name));
      if (!ref.mounted) return;
      state = state.copyWith(
        loaded: true,
        scenes: scenes,
        currentScene: current,
        inputs: inputs,
        audioInputs: audio,
        sceneItems: items,
        streamActive: stream.active,
        streamReconnecting: stream.reconnecting,
        recordActive: record.active,
        recordPaused: record.paused,
        replayActive: replay,
      );
    } on ParallelWaitError<dynamic, dynamic> {
      // Connection dropped mid-way; the reconnect will refresh again.
    } on ObsFailure {
      // Same as above.
    }
  }

  Future<Map<String, List<ObsSceneItem>>> _loadSceneItems(
    Iterable<String> sceneNames,
  ) async {
    final repo = ref.read(obsRepositoryProvider);
    final entries = await Future.wait(
      sceneNames.map((name) async {
        try {
          return MapEntry(name, await repo.getSceneItems(name));
        } on ObsFailure {
          return MapEntry(name, const <ObsSceneItem>[]);
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<void> _reloadScenes() async {
    try {
      final scenes = await ref.read(obsRepositoryProvider).getScenes();
      final items = await _loadSceneItems(scenes.map((s) => s.name));
      if (ref.mounted) {
        state = state.copyWith(scenes: scenes, sceneItems: items);
      }
    } on ObsFailure {
      // ignore: lost connection
    }
  }

  Future<void> _reloadSceneItems(String sceneName) async {
    final items = await _loadSceneItems([sceneName]);
    if (!ref.mounted) return;
    state = state.copyWith(sceneItems: {...state.sceneItems, ...items});
  }

  Future<void> _reloadInputs() async {
    final repo = ref.read(obsRepositoryProvider);
    try {
      final (inputs, audio) = await (
        repo.getInputs(),
        repo.getAudioInputs(),
      ).wait;
      if (ref.mounted) {
        state = state.copyWith(inputs: inputs, audioInputs: audio);
      }
    } on ParallelWaitError<dynamic, dynamic> {
      // ignore: lost connection
    }
  }

  void _onEvent(ObsEvent event) {
    switch (event) {
      case CurrentSceneChanged(:final sceneName):
        state = state.copyWith(currentScene: sceneName);
      case SceneListChanged():
        unawaited(_reloadScenes());
      case SceneItemsChanged(:final sceneName):
        unawaited(_reloadSceneItems(sceneName));
      case SceneItemEnabledChanged(
        :final sceneName,
        :final itemId,
        :final enabled,
      ):
        final items = state.sceneItems[sceneName];
        if (items == null) return;
        state = state.copyWith(
          sceneItems: {
            ...state.sceneItems,
            sceneName: [
              for (final item in items)
                item.id == itemId
                    ? ObsSceneItem(
                        id: item.id,
                        sourceName: item.sourceName,
                        enabled: enabled,
                        inputKind: item.inputKind,
                      )
                    : item,
            ],
          },
        );
      case InputListChanged() || InputRenamed():
        unawaited(_reloadInputs());
        unawaited(_reloadScenes());
      case InputMuteChanged(:final inputName, :final muted):
        state = state.copyWith(
          audioInputs: [
            for (final input in state.audioInputs)
              input.name == inputName
                  ? ObsAudioInput(
                      name: input.name,
                      volumeMul: input.volumeMul,
                      muted: muted,
                    )
                  : input,
          ],
        );
      case InputVolumeChanged(:final inputName, :final volumeMul):
        state = state.copyWith(
          audioInputs: [
            for (final input in state.audioInputs)
              input.name == inputName
                  ? ObsAudioInput(
                      name: input.name,
                      volumeMul: volumeMul,
                      muted: input.muted,
                    )
                  : input,
          ],
        );
      case StreamStateChanged(:final active):
        state = state.copyWith(
          streamActive: active,
          streamReconnecting: event.reconnecting,
        );
      case RecordStateChanged(:final active):
        state = state.copyWith(
          recordActive: active,
          recordPaused: active && event.paused
              ? true
              : event.resumed || !active
              ? false
              : null,
        );
      case ReplayBufferStateChanged(:final active):
        state = state.copyWith(replayActive: active);
      case MediaPlaybackStarted(:final inputName):
        state = state.copyWith(
          playingMedia: {...state.playingMedia, inputName},
        );
      case MediaPlaybackEnded(:final inputName):
        state = state.copyWith(
          playingMedia: {...state.playingMedia}..remove(inputName),
        );
      case InputVolumeMeters() || ObsExiting():
        break;
    }
  }

  /// Optimistic update used right after the user taps a pad.
  void markMediaStopped(String inputName) {
    state = state.copyWith(
      playingMedia: {...state.playingMedia}..remove(inputName),
    );
  }
}

final obsLiveStateProvider =
    NotifierProvider<ObsLiveStateNotifier, ObsLiveState>(
      ObsLiveStateNotifier.new,
    );
