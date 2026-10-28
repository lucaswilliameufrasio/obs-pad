import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/json.dart';
import '../../domain/pad/pad_models.dart';
import '../../domain/sound/sound_models.dart';

/// A list of profiles plus which one is active, saved as one JSON blob.
class ProfileList<T> {
  const ProfileList({required this.items, this.activeId});

  final List<T> items;
  final String? activeId;
}

class _JsonProfileStore<T> {
  _JsonProfileStore(
    this._prefs,
    this._key, {
    required this.fromJson,
    required this.toJson,
  });

  final SharedPreferences _prefs;
  final String _key;
  final T Function(JsonMap) fromJson;
  final JsonMap Function(T) toJson;

  ProfileList<T>? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = asJsonMap(jsonDecode(raw));
      return ProfileList(
        items: json.objects('items').map(fromJson).toList(),
        activeId: json.strOrNull('active'),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(ProfileList<T> list) => _prefs.setString(
    _key,
    jsonEncode({
      'items': list.items.map(toJson).toList(),
      'active': ?list.activeId,
    }),
  );
}

/// Button grids ("Live", "Gravação", "Só áudio"...).
class PadLayoutStore extends _JsonProfileStore<PadLayout> {
  PadLayoutStore(SharedPreferences prefs)
    : super(
        prefs,
        'pad_layouts_v1',
        fromJson: PadLayout.fromJson,
        toJson: (l) => l.toJson(),
      );
}

/// Soundboard profiles -> pages -> pads.
class SoundboardStore extends _JsonProfileStore<SoundboardProfile> {
  SoundboardStore(SharedPreferences prefs)
    : super(
        prefs,
        'soundboard_v1',
        fromJson: SoundboardProfile.fromJson,
        toJson: (p) => p.toJson(),
      );
}
