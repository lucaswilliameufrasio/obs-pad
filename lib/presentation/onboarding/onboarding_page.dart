import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/connection_profile.dart';
import '../../l10n/app_localizations.dart';
import '../profiles/connection_form.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// 4-step guided setup: open OBS, enable WebSocket, same Wi-Fi, test.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  static const stepCount = 4;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _step = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    await _controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish(ConnectionProfile profile, String password) async {
    await ref.read(profilesProvider.notifier).upsert(profile, password);
    await ref.read(profilesProvider.notifier).setActive(profile.id);
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboardingDone: true));
    if (!mounted) return;
    context.go('/pad');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider);
    final existing = profiles.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.stepOf(_step + 1, OnboardingPage.stepCount)),
        leading: _step > 0
            ? IconButton(
                tooltip: l.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goTo(_step - 1),
              )
            : (context.canPop() ? const CloseButton() : null),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / OnboardingPage.stepCount,
          ),
        ),
      ),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepPage(
            illustration: const StepIllustration(
              icons: [Icons.videocam_rounded],
              badge: 'OBS 28+',
            ),
            title: l.onbStep1Title,
            children: [
              Text(l.onbStep1Body, style: _body(context)),
              const SizedBox(height: 16),
              HintCard(text: l.onbStep1Hint, icon: Icons.help_outline),
            ],
          ),
          _StepPage(
            illustration: const StepIllustration(
              icons: [Icons.build_rounded, Icons.settings_input_antenna],
              connector: Icons.arrow_forward,
            ),
            title: l.onbStep2Title,
            children: [
              NumberedStep(number: 1, text: l.onbStep2a),
              NumberedStep(number: 2, text: l.onbStep2b),
              NumberedStep(number: 3, text: l.onbStep2c),
              NumberedStep(number: 4, text: l.onbStep2d),
              NumberedStep(number: 5, text: l.onbStep2e),
              const SizedBox(height: 12),
              const _ObsDialogMock(),
              const SizedBox(height: 12),
              HintCard(text: l.onbStep2Hint),
            ],
          ),
          _StepPage(
            illustration: const StepIllustration(
              icons: [Icons.computer, Icons.wifi, Icons.smartphone],
            ),
            title: l.onbStep3Title,
            children: [
              Text(l.onbStep3Body, style: _body(context)),
              const SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.search),
                  title: Text(l.onbFindIp),
                  initiallyExpanded: true,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OsTip(icon: Icons.window, text: l.onbIpWindows),
                    _OsTip(icon: Icons.laptop_mac, text: l.onbIpMac),
                    _OsTip(icon: Icons.terminal, text: l.onbIpLinux),
                  ],
                ),
              ),
            ],
          ),
          _StepPage(
            illustration: const StepIllustration(
              icons: [Icons.smartphone, Icons.videocam_rounded],
              connector: Icons.sync_alt,
            ),
            title: l.onbStep4Title,
            showNext: false,
            children: [
              Text(l.onbStep4Body, style: _body(context)),
              const SizedBox(height: 16),
              ConnectionForm(
                initial: existing,
                saveLabel: l.done,
                onSaved: _finish,
                footer: HintCard(
                  title: l.onbSoundTipTitle,
                  text: l.onbSoundTip,
                  icon: Icons.music_note,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _step < OnboardingPage.stepCount - 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  key: const Key('btn-next'),
                  onPressed: () => _goTo(_step + 1),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(l.next),
                ),
              ),
            )
          : null,
    );
  }

  TextStyle? _body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.illustration,
    required this.title,
    required this.children,
    this.showNext = true,
  });

  final Widget illustration;
  final String title;
  final List<Widget> children;
  final bool showNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        illustration,
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _OsTip extends StatelessWidget {
  const _OsTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Drawing of the OBS "WebSocket Server Settings" window so people know what
/// to look for.
class _ObsDialogMock extends StatelessWidget {
  const _ObsDialogMock();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodySmall;
    Widget check(String label) => Row(
      children: [
        Icon(Icons.check_box, size: 18, color: colors.primary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: text)),
      ],
    );
    final l = AppLocalizations.of(context);
    return Semantics(
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: colors.surfaceContainerHighest,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              l.obsMockTitle,
              style: text?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 8),
            check(l.obsMockEnableServer),
            check(l.obsMockEnableAuth),
            Row(
              children: [
                Text('${l.obsMockPort}: ', style: text),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.primary, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('4455', style: text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
