import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/connection_profile.dart';
import 'dashboard/dashboard_page.dart';
import 'home/home_shell.dart';
import 'mixer/mixer_page.dart';
import 'onboarding/onboarding_page.dart';
import 'pad/button_editor_page.dart';
import 'pad/pad_page.dart';
import 'profiles/profiles_page.dart';
import 'providers.dart';
import 'remote/remote_access_page.dart';
import 'settings/settings_page.dart';
import 'soundboard/add_sound_page.dart';
import 'soundboard/sound_pad_editor_page.dart';
import 'soundboard/soundboard_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final needsOnboarding =
      !ref.read(settingsProvider).onboardingDone &&
      ref.read(profilesProvider).profiles.isEmpty;

  return GoRouter(
    initialLocation: needsOnboarding ? '/onboarding' : '/pad',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/profiles', builder: (_, _) => const ProfilesPage()),
      GoRoute(
        path: '/profiles/edit',
        builder: (_, state) =>
            ProfileEditPage(profile: state.extra as ConnectionProfile?),
      ),
      GoRoute(path: '/remote', builder: (_, _) => const RemoteAccessPage()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/pad/button/:id',
        builder: (_, state) =>
            ButtonEditorPage(buttonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sounds/add/:pageId',
        builder: (_, state) =>
            AddSoundPage(pageId: state.pathParameters['pageId']!),
      ),
      GoRoute(
        path: '/sounds/pad/:pageId/:padId',
        builder: (_, state) => SoundPadEditorPage(
          pageId: state.pathParameters['pageId']!,
          padId: state.pathParameters['padId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/pad', builder: (_, _) => const PadPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/mixer', builder: (_, _) => const MixerPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sounds',
                builder: (_, _) => const SoundboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/metrics',
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
