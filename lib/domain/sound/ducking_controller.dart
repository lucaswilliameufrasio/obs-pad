import '../audio_math.dart';
import '../obs_failure.dart';

typedef VolumeReader = Future<double> Function(String inputName);
typedef VolumeWriter = Future<void> Function(String inputName, double mul);

/// Keeps the volumes from before ducking somewhere that survives the app
/// being closed, so they can be put back later.
abstract interface class DuckingMemory {
  Map<String, double> load();
  Future<void> save(Map<String, double> originals);
}

/// Lowers a target input while one or more sounds play and restores the
/// original volume when the last of them stops.
///
/// The original volume is only forgotten after OBS accepted the restore: if
/// the connection drops (or the app is closed) while a target is lowered,
/// [recover] puts it back on the next connection.
class DuckingController {
  DuckingController({
    required this.readVolume,
    required this.writeVolume,
    this.memory,
  }) {
    _original.addAll(memory?.load() ?? const {});
  }

  final VolumeReader readVolume;
  final VolumeWriter writeVolume;
  final DuckingMemory? memory;

  /// target input -> volume before ducking.
  final Map<String, double> _original = {};

  /// target input -> sounds currently holding it down.
  final Map<String, Set<String>> _holders = {};

  bool isDucked(String target) => _holders[target]?.isNotEmpty ?? false;

  Set<String> get duckedTargets => _holders.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => e.key)
      .toSet();

  /// Targets still lowered in OBS (or that may be) and waiting for a restore.
  Set<String> get pendingRestores => _original.keys.toSet();

  /// [sound] started: lower [target] by [reductionDb]. Calling it again for
  /// the same sound is a no-op.
  Future<void> duck({
    required String sound,
    required String target,
    required double reductionDb,
  }) async {
    final holders = _holders.putIfAbsent(target, () => <String>{});
    if (holders.contains(sound)) return;
    final firstHolder = holders.isEmpty;
    holders.add(sound);
    if (!firstHolder) return;

    // Still lowered from before (restore failed): keep the true original.
    final original = _original[target] ?? await readVolume(target);
    // A release may have happened while we were reading.
    if (!(_holders[target]?.contains(sound) ?? false)) return;
    _original[target] = original;
    await _persist();
    await writeVolume(target, original * dbToMul(-reductionDb.abs()));
  }

  /// [sound] ended: restore every target it was holding, when free.
  Future<void> release(String sound) async {
    final targets = _holders.entries
        .where((e) => e.value.contains(sound))
        .map((e) => e.key)
        .toList();
    for (final target in targets) {
      final holders = _holders[target]!..remove(sound);
      if (holders.isEmpty) await _restore(target);
    }
  }

  /// Panic button: put everything back.
  Future<void> releaseAll() async {
    _holders.clear();
    await _restoreEach(_original.keys.toList());
  }

  /// After (re)connecting: the playback events of the time offline were
  /// lost, so restore every target that is still waiting for it.
  Future<void> recover() => releaseAll();

  /// Restores every target even if some fail; rethrows the first failure.
  Future<void> _restoreEach(List<String> targets) async {
    Object? firstError;
    StackTrace? firstStack;
    for (final target in targets) {
      try {
        await _restore(target);
      } on Object catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  Future<void> _restore(String target) async {
    final original = _original[target];
    if (original == null) return;
    try {
      await writeVolume(target, original);
    } on ObsFailure catch (failure) {
      // Input deleted or renamed in OBS: nothing left to restore.
      if (failure.kind != ObsFailureKind.resourceNotFound) rethrow;
    }
    // Another sound may have ducked it again meanwhile.
    if (isDucked(target)) return;
    _original.remove(target);
    await _persist();
  }

  Future<void> _persist() async => memory?.save(Map.unmodifiable(_original));
}
