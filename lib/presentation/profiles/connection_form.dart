import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import '../../domain/connection_profile.dart';
import '../../domain/obs_failure.dart';
import '../../domain/obs_models.dart';
import '../../l10n/app_localizations.dart';
import '../companion/computer_helper.dart';
import '../companion/find_computers_sheet.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// IP/port/password fields + "Testar conexão" with a clear result.
class ConnectionForm extends ConsumerStatefulWidget {
  const ConnectionForm({
    required this.onSaved,
    this.initial,
    this.initialPassword = '',
    this.saveLabel,
    this.allowSaveWithoutTest = false,
    this.footer,
    super.key,
  });

  final ConnectionProfile? initial;
  final String initialPassword;

  /// Label of the button shown after a successful test.
  final String? saveLabel;
  final bool allowSaveWithoutTest;

  /// Extra content shown after a successful test (e.g. tips).
  final Widget? footer;
  final Future<void> Function(ConnectionProfile profile, String password)
  onSaved;

  @override
  ConsumerState<ConnectionForm> createState() => _ConnectionFormState();
}

sealed class _TestState {
  const _TestState();
}

class _Idle extends _TestState {
  const _Idle();
}

class _Testing extends _TestState {
  const _Testing();
}

class _Success extends _TestState {
  const _Success(this.info);
  final ObsServerInfo info;
}

class _Failed extends _TestState {
  const _Failed(this.failure);
  final ObsFailure failure;
}

class _ConnectionFormState extends ConsumerState<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _password;
  bool _obscure = true;
  bool _saving = false;
  _TestState _test = const _Idle();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name);
    _host = TextEditingController(text: widget.initial?.host);
    _port = TextEditingController(
      text: '${widget.initial?.port ?? defaultObsPort}',
    );
    _password = TextEditingController(text: widget.initialPassword);
    for (final c in [_host, _port, _password]) {
      c.addListener(_resetResult);
    }
  }

  void _resetResult() {
    if (_test is! _Idle && _test is! _Testing) {
      setState(() => _test = const _Idle());
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _host, _port, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  ConnectionProfile _profile(AppLocalizations l) {
    final name = _name.text.trim();
    return ConnectionProfile(
      id: widget.initial?.id ?? newId(),
      name: name.isEmpty ? l.defaultProfileName : name,
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? defaultObsPort,
    );
  }

  Future<void> _runTest() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _test = const _Testing());
    final config = _profile(l).toConfig(_password.text);
    try {
      final info = await ref.read(obsRepositoryProvider).testConnection(config);
      if (!mounted) return;
      setState(() => _test = _Success(info));
      if (ref.read(settingsProvider).haptics) {
        unawaited(HapticFeedback.mediumImpact());
      }
    } on ObsFailure catch (failure) {
      if (!mounted) return;
      setState(() => _test = _Failed(failure));
      if (ref.read(settingsProvider).haptics) {
        unawaited(HapticFeedback.heavyImpact());
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(
        _profile(AppLocalizations.of(context)),
        _password.text,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fill({
    required String host,
    required int port,
    String? name,
    String? password,
  }) {
    setState(() {
      _host.text = host;
      _port.text = '$port';
      if (name != null && _name.text.trim().isEmpty) _name.text = name;
      if (password != null) _password.text = password;
    });
  }

  Future<void> _findOnNetwork() async {
    FocusScope.of(context).unfocus();
    final computer = await showFindComputersSheet(context);
    if (computer == null || !mounted) return;
    _fill(
      host: computer.address,
      port: computer.announcement.obsPort,
      name: computer.announcement.name,
    );
  }

  Future<void> _readQr() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context);
    final text = await ref.read(qrScannerProvider)(context);
    if (text == null || !mounted) return;
    final link = ConnectionLink.tryParse(text);
    if (link == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.qrInvalid)));
      return;
    }
    _fill(
      host: link.host,
      port: link.port,
      name: link.name,
      password: link.password,
    );
    // Everything is filled: check it right away.
    await _runTest();
  }

  String? _validateHost(AppLocalizations l, String? value) =>
      switch (validateHost(value ?? '')) {
        null => null,
        HostValidation.empty => l.errHostEmpty,
        HostValidation.hasScheme => l.errHostScheme,
        HostValidation.hasPort => l.errHostPort,
        HostValidation.invalid => l.errHostInvalid,
      };

  String? _validatePort(AppLocalizations l, String? value) {
    final port = int.tryParse(value?.trim() ?? '');
    return port == null || port < 1 || port > 65535 ? l.errPort : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final test = _test;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn-find'),
                  onPressed: _findOnNetwork,
                  icon: const Icon(Icons.wifi_find),
                  label: Text(l.findOnNetwork),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn-read-qr'),
                  onPressed: _readQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.readQr),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l.findOrQrHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('field-name'),
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.fieldProfileName,
              hintText: l.defaultProfileName,
              prefixIcon: const Icon(Icons.computer),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: const Key('field-host'),
                  controller: _host,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.fieldHost,
                    hintText: l.fieldHostHint,
                    prefixIcon: const Icon(Icons.lan),
                  ),
                  validator: (v) => _validateHost(l, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('field-port'),
                  controller: _port,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l.fieldPort),
                  validator: (v) => _validatePort(l, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-password'),
            controller: _password,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) => _runTest(),
            decoration: InputDecoration(
              labelText: l.fieldPassword,
              helperText: l.fieldPasswordHint,
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                tooltip: l.showPassword,
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('btn-test'),
            onPressed: test is _Testing ? null : _runTest,
            icon: test is _Testing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(test is _Testing ? l.testing : l.testConnection),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (test) {
              _Failed(:final failure) => FailureCard(
                key: const Key('test-failure'),
                failure: failure,
              ),
              _Success(:final info) => Column(
                key: const Key('test-success'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SuccessCard(info: info),
                  if (widget.footer != null) ...[
                    const SizedBox(height: 12),
                    widget.footer!,
                  ],
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('btn-save'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(widget.saveLabel ?? l.save),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          if (widget.allowSaveWithoutTest && test is! _Success)
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(l.saveWithoutTest),
            ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.info});

  final ObsServerInfo info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final old = info.obsMajorVersion > 0 && info.obsMajorVersion < 28;
    return Card(
      elevation: 0,
      color: colors.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: colors.primary, size: 36),
        title: Text(
          l.testSuccess(info.obsVersion),
          style: TextStyle(color: colors.onPrimaryContainer),
        ),
        subtitle: old ? Text(l.testOldObs(info.obsVersion)) : null,
      ),
    );
  }
}
