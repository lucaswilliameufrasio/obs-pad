import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/ducking_memory_store.dart';
import '../../data/storage/layout_store.dart';
import '../../domain/obs_events.dart';
import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../../domain/sound/ducking_controller.dart';
import '../../domain/sound/sound_models.dart';
import '../connection/obs_live_state.dart';
import '../l10n_util.dart';
import '../providers.dart';

final soundboardStoreProvider = Provider<SoundboardStore>(
  (ref) => SoundboardStore(ref.watch(sharedPreferencesProvider)),
);

class SoundboardNotifier extends Notifier<ProfileList<SoundboardProfile>> {
  SoundboardStore get _store => ref.read(soundboardStoreProvider);

  @override
  ProfileList<SoundboardProfile> build() {
    final stored = ref.watch(soundboardStoreProvider).load();
    if (stored != null && stored.items.isNotEmpty) return stored;
    final l = l10nOf(ref);
    final profile = SoundboardProfile(
      id: 'main',
      name: l.soundProfileDefault,
      pages: [SoundPage(id: 'page-1', name: l.soundPageDefault)],
    );
    return ProfileList(items: [profile], activeId: profile.id);
  }

  SoundboardProfile get active =>
      state.items.where((p) => p.id == state.activeId).firstOrNull ??
      state.items.first;

  Iterable<SoundPad> get allPads => state.items.expand((p) => p.allPads);

  Future<void> _save(List<SoundboardProfile> items, {String? activeId}) async {
    state = ProfileList(items: items, activeId: activeId ?? state.activeId);
    await _store.save(state);
  }

  Future<void> _updateActive(
    SoundboardProfile Function(SoundboardProfile) change,
  ) {
    final id = active.id;
    return _save([for (final p in state.items) p.id == id ? change(p) : p]);
  }

  Future<void> _updatePage(
    String pageId,
    SoundPage Function(SoundPage) change,
  ) => _updateActive(
    (profile) => profile.copyWith(
      pages: [
        for (final page in profile.pages)
          page.id == pageId ? change(page) : page,
      ],
    ),
  );

  Future<void> setActiveProfile(String id) => _save(state.items, activeId: id);

  Future<void> addProfile(String name) {
    final l = l10nOf(ref);
    final profile = SoundboardProfile(
      id: newId(),
      name: name,
      pages: [SoundPage(id: newId(), name: l.soundPageDefault)],
    );
    return _save([...state.items, profile], activeId: profile.id);
  }

  Future<void> renameProfile(String name) =>
      _updateActive((p) => p.copyWith(name: name));

  Future<void> deleteActiveProfile() async {
    if (state.items.length <= 1) return;
    final id = active.id;
    final items = state.items.where((p) => p.id != id).toList();
    await _save(items, activeId: items.first.id);
  }

  Future<String> addPage(String name) async {
    final page = SoundPage(id: newId(), name: name);
    await _updateActive((p) => p.copyWith(pages: [...p.pages, page]));
    return page.id;
  }

  Future<void> renamePage(String pageId, String name) =>
      _updatePage(pageId, (p) => p.copyWith(name: name));

  Future<void> deletePage(String pageId) => _updateActive((profile) {
    if (profile.pages.length <= 1) return profile;
    return profile.copyWith(
      pages: profile.pages.where((p) => p.id != pageId).toList(),
    );
  });

  Future<void> upsertPad(String pageId, SoundPad pad) =>
      _updatePage(pageId, (page) {
        final pads = [...page.pads];
        final index = pads.indexWhere((p) => p.id == pad.id);
        if (index >= 0) {
          pads[index] = pad;
        } else {
          pads.add(pad);
        }
        return page.copyWith(pads: pads);
      });

  Future<void> deletePad(String pageId, String padId) => _updatePage(
    pageId,
    (page) =>
        page.copyWith(pads: page.pads.where((p) => p.id != padId).toList()),
  );

  Future<void> reorderPads(String pageId, List<SoundPad> pads) =>
      _updatePage(pageId, (page) => page.copyWith(pads: pads));
}

final soundboardProvider =
    NotifierProvider<SoundboardNotifier, ProfileList<SoundboardProfile>>(
      SoundboardNotifier.new,
    );

final activeSoundboardProvider = Provider<SoundboardProfile>((ref) {
  ref.watch(soundboardProvider);
  return ref.read(soundboardProvider.notifier).active;
});

/// Plays pads through obs-websocket media actions and handles ducking.
class SoundPlayer {
  SoundPlayer(this._ref) {
    final repo = _ref.read(obsRepositoryProvider);
    ducking = DuckingController(
      readVolume: repo.getInputVolume,
      writeVolume: repo.setInputVolume,
      memory: DuckingMemoryStore(_ref.read(sharedPreferencesProvider)),
    );
  }

  final Ref _ref;
  late final DuckingController ducking;

  void _ignore(Future<void> future) =>
      unawaited(future.catchError((Object _) {}));

  /// Called on every successful connection: puts back any volume left
  /// lowered by a sound that was playing when the connection dropped or the
  /// app was closed.
  void onConnected() => _ignore(ducking.recover());

  void onEvent(ObsEvent event) {
    switch (event) {
      case MediaPlaybackStarted(:final inputName):
        // Also covers sounds started from OBS itself or another device.
        final pad = _ref
            .read(soundboardProvider.notifier)
            .allPads
            .where((p) => p.inputName == inputName && p.ducking != null)
            .firstOrNull;
        if (pad != null) _ignore(_duck(pad));
      case MediaPlaybackEnded(:final inputName):
        _ignore(ducking.release(inputName));
      default:
        break;
    }
  }

  Future<void> _duck(SoundPad pad) async {
    final config = pad.ducking;
    if (config == null || config.inputName.isEmpty) return;
    await ducking.duck(
      sound: pad.inputName,
      target: config.inputName,
      reductionDb: config.reductionDb,
    );
  }

  Future<void> _media(String input, ObsMediaAction action) =>
      _ref.read(obsRepositoryProvider).triggerMediaAction(input, action);

  /// Play from the start (restart).
  Future<void> start(SoundPad pad) async {
    try {
      await _duck(pad);
    } on ObsFailure catch (failure) {
      // A missing duck target should not stop the sound from playing.
      if (failure.isConnectionProblem) rethrow;
    }
    // OBS answers "ok" even when it cannot play the sound (not in the
    // scene on air); only the playback event tells it really started.
    final started = _waitForPlayback(pad.inputName);
    try {
      await _media(pad.inputName, ObsMediaAction.restart);
      if (!await started.result) {
        throw ObsFailure(ObsFailureKind.soundNotOnAir, resource: pad.inputName);
      }
    } on ObsFailure {
      started.cancel();
      _ignore(ducking.release(pad.inputName));
      rethrow;
    }
  }

  /// How long to wait for MediaInputPlaybackStarted (normally ~50 ms).
  static const playbackStartTimeout = Duration(milliseconds: 2500);

  ({Future<bool> result, void Function() cancel}) _waitForPlayback(
    String inputName,
  ) {
    final completer = Completer<bool>();
    late final StreamSubscription<ObsEvent> sub;
    late final Timer timer;
    void finish(bool value) {
      if (completer.isCompleted) return;
      timer.cancel();
      unawaited(sub.cancel());
      completer.complete(value);
    }

    sub = _ref.read(obsEventsProvider).listen((event) {
      if (event is MediaPlaybackStarted && event.inputName == inputName) {
        finish(true);
      }
    });
    timer = Timer(playbackStartTimeout, () => finish(false));
    return (result: completer.future, cancel: () => finish(false));
  }

  Future<void> stop(SoundPad pad) async {
    _ref.read(obsLiveStateProvider.notifier).markMediaStopped(pad.inputName);
    try {
      await _media(pad.inputName, ObsMediaAction.stop);
    } finally {
      _ignore(ducking.release(pad.inputName));
    }
  }

  Future<void> pause(SoundPad pad) =>
      _media(pad.inputName, ObsMediaAction.pause);

  Future<void> resume(SoundPad pad) =>
      _media(pad.inputName, ObsMediaAction.play);

  /// Panic button: stop every sound of every profile and restore volumes.
  /// Returns how many sounds could not be stopped.
  Future<int> stopAll() async {
    final inputs = _ref
        .read(soundboardProvider.notifier)
        .allPads
        .map((p) => p.inputName)
        .where((name) => name.isNotEmpty)
        .toSet();
    final live = _ref.read(obsLiveStateProvider.notifier);
    final results = await Future.wait(
      inputs.map((input) async {
        live.markMediaStopped(input);
        try {
          await _media(input, ObsMediaAction.stop);
          return true;
        } on ObsFailure catch (failure) {
          if (failure.isConnectionProblem) rethrow;
          return false;
        }
      }),
    );
    await ducking.releaseAll();
    return results.where((ok) => !ok).length;
  }

  /// Push the pad volume/loop settings to OBS.
  Future<void> apply(SoundPad pad) async {
    final volume = pad.volumeMul;
    final repo = _ref.read(obsRepositoryProvider);
    if (volume != null) await repo.setInputVolume(pad.inputName, volume);
    await repo.setMediaLooping(pad.inputName, loop: pad.loop);
  }
}

final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = SoundPlayer(ref);
  final sub = ref.watch(obsEventsProvider).listen(player.onEvent);
  ref.listen(connectionStatusProvider, (previous, next) {
    if (next is ObsConnected && previous is! ObsConnected) player.onConnected();
  });
  if (ref.read(connectionStatusProvider) is ObsConnected) player.onConnected();
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(player.ducking.releaseAll().catchError((Object _) {}));
  });
  return player;
});
