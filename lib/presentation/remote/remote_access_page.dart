import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';

/// Explains Tailscale / NetBird in plain steps, and warns against exposing
/// port 4455 on the internet.
class RemoteAccessPage extends StatelessWidget {
  const RemoteAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.remoteTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepIllustration(
            icons: [Icons.smartphone, Icons.vpn_lock, Icons.computer],
          ),
          const SizedBox(height: 20),
          Text(l.remoteIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          HintCard(
            warning: true,
            icon: Icons.gpp_bad_outlined,
            title: l.remoteWarningTitle,
            text: l.remoteWarning,
          ),
          const SizedBox(height: 16),
          _VpnCard(
            title: l.remoteOptionTailscale,
            app: 'Tailscale',
            site: 'tailscale.com',
          ),
          _VpnCard(
            title: l.remoteOptionNetbird,
            app: 'NetBird',
            site: 'netbird.io',
          ),
          const SizedBox(height: 8),
          HintCard(text: l.remoteFootnote, icon: Icons.info_outline),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/profiles/edit'),
            icon: const Icon(Icons.add),
            label: Text(l.remoteAddProfile),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _VpnCard extends StatelessWidget {
  const _VpnCard({required this.title, required this.app, required this.site});

  final String title;
  final String app;
  final String site;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.shield_outlined),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          NumberedStep(number: 1, text: l.remoteStep1(site)),
          NumberedStep(number: 2, text: l.remoteStep2(app)),
          NumberedStep(number: 3, text: l.remoteStep3(app)),
          NumberedStep(number: 4, text: l.remoteStep4(app)),
          NumberedStep(number: 5, text: l.remoteStep5),
        ],
      ),
    );
  }
}
