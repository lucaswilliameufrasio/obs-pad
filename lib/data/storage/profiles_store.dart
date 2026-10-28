import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/json.dart';
import '../../domain/connection_profile.dart';

/// Where passwords are kept. Abstracted so tests do not need platform code.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Connection profiles in shared_preferences, passwords in [SecretStore].
class ProfilesStore {
  ProfilesStore(this._prefs, this._secrets);

  static const _profilesKey = 'connection_profiles_v1';
  static const _activeKey = 'active_profile_id';

  final SharedPreferences _prefs;
  final SecretStore _secrets;

  String _passwordKey(String id) => 'obs_password_$id';

  List<ConnectionProfile> loadProfiles() {
    final raw = _prefs.getString(_profilesKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map((e) => ConnectionProfile.fromJson(asJsonMap(e))).toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveProfiles(List<ConnectionProfile> profiles) =>
      _prefs.setString(
        _profilesKey,
        jsonEncode(profiles.map((p) => p.toJson()).toList()),
      );

  String? get activeProfileId => _prefs.getString(_activeKey);

  Future<void> setActiveProfileId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeKey);
    } else {
      await _prefs.setString(_activeKey, id);
    }
  }

  Future<String> readPassword(String profileId) async =>
      await _secrets.read(_passwordKey(profileId)) ?? '';

  Future<void> writePassword(String profileId, String password) =>
      password.isEmpty
      ? _secrets.delete(_passwordKey(profileId))
      : _secrets.write(_passwordKey(profileId), password);

  Future<void> deletePassword(String profileId) =>
      _secrets.delete(_passwordKey(profileId));
}
