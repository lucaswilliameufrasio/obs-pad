import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'desktop_controller.dart';
import 'l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final DesktopController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DesktopController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(l.appSubtitle),
                const SizedBox(height: 16),
                if (c.serverFailed)
                  _Banner(text: l.serverFailed, icon: Icons.error_outline),
                _ObsCard(controller: c),
                if (c.readyForPhone) _ConnectCard(controller: c),
                _SoundsCard(controller: c),
                if (c.system.isWindows) _FirewallCard(controller: c),
                _ActivityCard(controller: c),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? Colors.green : scheme.outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: scheme.onErrorContainer),
        title: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}

class _ObsCard extends StatefulWidget {
  const _ObsCard({required this.controller});

  final DesktopController controller;

  @override
  State<_ObsCard> createState() => _ObsCardState();
}

class _ObsCardState extends State<_ObsCard> {
  EnableResult? _result;
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    final result = await widget.controller.enableForPhone();
    if (mounted) {
      setState(() {
        _busy = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.controller;
    final settings = c.settings;
    if (c.settingsFile == null) {
      return _Section(
        title: l.obsSection,
        icon: Icons.videocam_outlined,
        children: [Text(l.obsNotFound)],
      );
    }
    final enabled = settings?.enabled ?? false;
    final ready = c.readyForPhone;
    return _Section(
      title: l.obsSection,
      icon: Icons.videocam_outlined,
      children: [
        _StatusLine(
          ok: c.obsRunning,
          text: c.obsRunning ? l.obsRunning : l.obsClosed,
        ),
        _StatusLine(
          ok: ready,
          text: ready
              ? l.phoneControlOn(settings!.port)
              : enabled
              ? l.phoneControlNoPassword
              : l.phoneControlOff,
        ),
        if (!ready) ...[
          const SizedBox(height: 12),
          Text(l.enableExplain),
          if (c.obsRunning) ...[
            const SizedBox(height: 8),
            Text(
              l.enableNeedsClosedObs,
              key: const Key('needs-closed-obs'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('btn-enable'),
            onPressed: c.obsRunning || _busy ? null : _enable,
            icon: const Icon(Icons.power_settings_new),
            label: Text(l.enableButton),
          ),
        ],
        if (_result == EnableResult.enabled && ready) ...[
          const SizedBox(height: 8),
          Text(l.enableDone, key: const Key('enable-done')),
        ],
        if (_result == EnableResult.failed) ...[
          const SizedBox(height: 8),
          Text(l.enableFailed),
        ],
      ],
    );
  }
}

class _ConnectCard extends StatefulWidget {
  const _ConnectCard({required this.controller});

  final DesktopController controller;

  @override
  State<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends State<_ConnectCard> {
  bool _showQr = false;
  bool _showPassword = false;

  void _copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).copied)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.controller;
    final settings = c.settings!;
    final link = c.connectionLink;
    return _Section(
      title: l.connectSection,
      icon: Icons.phone_android,
      children: [
        Text(l.connectHowTo),
        const SizedBox(height: 12),
        if (c.addresses.isEmpty)
          Text(l.noAddress)
        else ...[
          for (final address in c.addresses)
            _CopyRow(
              label: l.addressLabel,
              value: address.vpn ? l.addressVpn(address.ip) : address.ip,
              onCopy: () => _copy(address.ip),
            ),
          _CopyRow(
            label: l.portLabel,
            value: '${settings.port}',
            onCopy: () => _copy('${settings.port}'),
          ),
          _CopyRow(
            label: l.passwordLabel,
            value: _showPassword ? settings.password : '••••••••',
            onCopy: () => _copy(settings.password),
            extra: TextButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              child: Text(l.showPassword),
            ),
          ),
        ],
        if (link != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('btn-qr'),
            onPressed: () => setState(() => _showQr = !_showQr),
            icon: const Icon(Icons.qr_code_2),
            label: Text(_showQr ? l.hideQr : l.showQr),
          ),
          if (_showQr) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  key: const Key('qr'),
                  data: link.toObsPadUri(),
                  size: 240,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.qrWarning, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.extra,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 150, child: Text(label)),
      Expanded(
        child: SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      ?extra,
      IconButton(
        tooltip: AppLocalizations.of(context).copy,
        onPressed: onCopy,
        icon: const Icon(Icons.copy, size: 18),
      ),
    ],
  );
}

class _SoundsCard extends StatelessWidget {
  const _SoundsCard({required this.controller});

  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dir = controller.system.soundsDir;
    return _Section(
      title: l.soundsSection,
      icon: Icons.music_note_outlined,
      children: [
        Text(l.soundsFolder),
        const SizedBox(height: 4),
        SelectableText(
          dir.path,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(l.soundsCount(controller.soundCount)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => unawaited(controller.system.openFolder(dir)),
          icon: const Icon(Icons.folder_open),
          label: Text(l.openFolder),
        ),
      ],
    );
  }
}

class _FirewallCard extends StatefulWidget {
  const _FirewallCard({required this.controller});

  final DesktopController controller;

  @override
  State<_FirewallCard> createState() => _FirewallCardState();
}

class _FirewallCardState extends State<_FirewallCard> {
  bool? _allowed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.controller;
    return _Section(
      title: l.firewallSection,
      icon: Icons.shield_outlined,
      children: [
        Text(l.firewallExplain),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final allowed = await c.system.allowThroughFirewall(
              obsPort: c.settings?.port ?? 4455,
            );
            if (mounted) setState(() => _allowed = allowed);
          },
          icon: const Icon(Icons.shield),
          label: Text(l.firewallButton),
        ),
        if (_allowed != null) ...[
          const SizedBox(height: 8),
          Text(_allowed! ? l.firewallDone : l.firewallFailed),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.controller});

  final DesktopController controller;

  String _describe(AppLocalizations l, CompanionActivity a) => switch (a.kind) {
    CompanionActivityKind.discovered => l.activityDiscovered(a.remote),
    CompanionActivityKind.listed => l.activityListed,
    CompanionActivityKind.uploaded => l.activityUploaded(a.detail),
    CompanionActivityKind.rejected =>
      a.detail == 'unauthorized'
          ? l.activityRejected(a.remote)
          : l.activityRejectedOther(a.remote, a.detail),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = controller.activity;
    return _Section(
      title: l.activitySection,
      icon: Icons.history,
      children: [
        if (items.isEmpty) Text(l.activityEmpty),
        for (final a in items.take(10))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${TimeOfDay.fromDateTime(a.time).format(context)}  '
              '${_describe(l, a)}',
            ),
          ),
      ],
    );
  }
}
