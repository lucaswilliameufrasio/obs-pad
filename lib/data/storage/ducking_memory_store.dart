import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sound/ducking_controller.dart';

/// Saves the volumes from before ducking, so a lowered music input can be
/// restored even after the app was closed mid-sound.
class DuckingMemoryStore implements DuckingMemory {
  DuckingMemoryStore(this._prefs);

  static const _key = 'ducking_originals_v1';

  final SharedPreferences _prefs;

  @override
  Map<String, double> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return {};
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (value is num) key: value.toDouble(),
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, double> originals) async {
    if (originals.isEmpty) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, jsonEncode(originals));
    }
  }
}
