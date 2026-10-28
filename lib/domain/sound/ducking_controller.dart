import '../audio_math.dart';

typedef VolumeReader = Future<double> Function(String inputName);
typedef VolumeWriter = Future<void> Function(String inputName, double mul);

/// Lowers a target input while one or more sounds play and restores the
/// original volume when the last of them stops.
class DuckingController {
  DuckingController({required this.readVolume, required this.writeVolume});

  final VolumeReader readVolume;
  final VolumeWriter writeVolume;

  /// target input -> volume before ducking.
  final Map<String, double> _original = {};

  /// target input -> sounds currently holding it down.
  final Map<String, Set<String>> _holders = {};

  bool isDucked(String target) => _holders[target]?.isNotEmpty ?? false;

  Set<String> get duckedTargets => _holders.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => e.key)
      .toSet();

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

    final original = await readVolume(target);
    // A release may have happened while we were reading.
    if (!(_holders[target]?.contains(sound) ?? false)) return;
    _original[target] = original;
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
    final targets = _original.keys.toList();
    _holders.clear();
    for (final target in targets) {
      await _restore(target);
    }
  }

  Future<void> _restore(String target) async {
    final original = _original.remove(target);
    if (original != null) await writeVolume(target, original);
  }
}
