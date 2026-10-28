import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/obs/websocket_obs_repository.dart';
import '../data/storage/profiles_store.dart';
import '../data/storage/settings_store.dart';
import '../domain/connection_profile.dart';
import '../domain/obs_events.dart';
import '../domain/obs_models.dart';
import '../domain/obs_repository.dart';

/// Overridden in `main()` with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not set'),
);

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

final obsRepositoryProvider = Provider<ObsRepository>((ref) {
  final repository = WebSocketObsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final profilesStoreProvider = Provider<ProfilesStore>(
  (ref) => ProfilesStore(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secretStoreProvider),
  ),
);

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(sharedPreferencesProvider)),
);

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).load();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsStoreProvider).save(state);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Light haptic tick, respecting the user setting.
void tapFeedback(WidgetRef ref) {
  if (ref.read(settingsProvider).haptics) {
    unawaited(HapticFeedback.lightImpact());
  }
}

// -----------------------------------------------------------------------------
// Connection profiles
// -----------------------------------------------------------------------------

class ProfilesState {
  const ProfilesState({required this.profiles, this.activeId});

  final List<ConnectionProfile> profiles;
  final String? activeId;

  ConnectionProfile? get active =>
      profiles.where((p) => p.id == activeId).firstOrNull ??
      profiles.firstOrNull;
}

class ProfilesNotifier extends Notifier<ProfilesState> {
  ProfilesStore get _store => ref.read(profilesStoreProvider);

  @override
  ProfilesState build() {
    final store = ref.watch(profilesStoreProvider);
    return ProfilesState(
      profiles: store.loadProfiles(),
      activeId: store.activeProfileId,
    );
  }

  Future<void> upsert(ConnectionProfile profile, String password) async {
    final list = [...state.profiles];
    final index = list.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      list[index] = profile;
    } else {
      list.add(profile);
    }
    await _store.writePassword(profile.id, password);
    await _store.saveProfiles(list);
    state = ProfilesState(profiles: list, activeId: state.activeId);
  }

  Future<void> remove(String id) async {
    final list = state.profiles.where((p) => p.id != id).toList();
    await _store.deletePassword(id);
    await _store.saveProfiles(list);
    final activeId = state.activeId == id
        ? list.firstOrNull?.id
        : state.activeId;
    await _store.setActiveProfileId(activeId);
    state = ProfilesState(profiles: list, activeId: activeId);
  }

  Future<void> setActive(String id) async {
    await _store.setActiveProfileId(id);
    state = ProfilesState(profiles: state.profiles, activeId: id);
  }

  Future<String> passwordOf(String id) => _store.readPassword(id);
}

final profilesProvider = NotifierProvider<ProfilesNotifier, ProfilesState>(
  ProfilesNotifier.new,
);

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

// -----------------------------------------------------------------------------
// Connection
// -----------------------------------------------------------------------------

class ConnectionStatusNotifier extends Notifier<ObsConnectionStatus> {
  @override
  ObsConnectionStatus build() {
    final repository = ref.watch(obsRepositoryProvider);
    final sub = repository.statusChanges.listen((status) => state = status);
    ref.onDispose(sub.cancel);
    return repository.status;
  }
}

final connectionStatusProvider =
    NotifierProvider<ConnectionStatusNotifier, ObsConnectionStatus>(
      ConnectionStatusNotifier.new,
    );

final isConnectedProvider = Provider<bool>(
  (ref) => ref.watch(connectionStatusProvider) is ObsConnected,
);

final obsEventsProvider = Provider<Stream<ObsEvent>>(
  (ref) => ref.watch(obsRepositoryProvider).events,
);

/// Connects to the active profile. Failures are reported via the status.
class ConnectionController {
  ConnectionController(this._ref);

  final Ref _ref;

  Future<void> connectActive() async {
    final profiles = _ref.read(profilesProvider);
    final profile = profiles.active;
    if (profile == null) return;
    final password = await _ref
        .read(profilesProvider.notifier)
        .passwordOf(profile.id);
    try {
      await _ref
          .read(obsRepositoryProvider)
          .connect(profile.toConfig(password));
    } on Exception {
      // Status stream already carries the failure / reconnect info.
    }
  }

  Future<void> switchTo(String profileId) async {
    await _ref.read(profilesProvider.notifier).setActive(profileId);
    await connectActive();
  }
}

final connectionControllerProvider = Provider<ConnectionController>(
  ConnectionController.new,
);
