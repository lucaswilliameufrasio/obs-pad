import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/connection_profile.dart';
import '../../domain/obs_models.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'connection_form.dart';

class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(profilesProvider);
    final status = ref.watch(connectionStatusProvider);
    final activeId = state.active?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l.profilesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profiles/edit'),
        icon: const Icon(Icons.add),
        label: Text(l.addProfile),
      ),
      body: state.profiles.isEmpty
          ? EmptyState(icon: Icons.computer, message: l.profilesEmpty)
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final profile in state.profiles)
                  ListTile(
                    leading: Icon(
                      profile.id == activeId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(profile.name),
                    subtitle: Text(
                      '${profile.host}:${profile.port}'
                      '${profile.id == activeId && status is ObsConnected ? ' • ${l.statusConnected}' : ''}',
                    ),
                    onTap: () async {
                      await ref
                          .read(connectionControllerProvider)
                          .switchTo(profile.id);
                      if (context.mounted) context.pop();
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await context.push('/profiles/edit', extra: profile);
                        } else if (value == 'delete') {
                          await _confirmDelete(context, ref, profile);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ConnectionProfile profile,
  ) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteProfileConfirm(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      final wasActive = ref.read(profilesProvider).active?.id == profile.id;
      await ref.read(profilesProvider.notifier).remove(profile.id);
      if (wasActive) {
        await ref.read(obsRepositoryProvider).disconnect();
        await ref.read(connectionControllerProvider).connectActive();
      }
    }
  }
}

class ProfileEditPage extends ConsumerWidget {
  const ProfileEditPage({this.profile, this.presetHost, super.key});

  final ConnectionProfile? profile;
  final String? presetHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final existing = profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? l.addProfile : l.editProfile),
      ),
      body: FutureBuilder<String>(
        future: existing == null
            ? Future.value('')
            : ref.read(profilesProvider.notifier).passwordOf(existing.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ConnectionForm(
                initial: existing,
                initialPassword: snapshot.data!,
                allowSaveWithoutTest: true,
                onSaved: (saved, password) async {
                  final notifier = ref.read(profilesProvider.notifier);
                  await notifier.upsert(saved, password);
                  final isActive = ref.read(profilesProvider).active?.id;
                  if (existing == null || isActive == saved.id) {
                    await ref
                        .read(connectionControllerProvider)
                        .switchTo(saved.id);
                  }
                  if (context.mounted) context.pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
