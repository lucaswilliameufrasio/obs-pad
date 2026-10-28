import 'package:flutter/material.dart';

import '../../domain/obs_failure.dart';
import '../../l10n/app_localizations.dart';
import '../failure_text.dart';

/// Big friendly picture made of icons, used by the setup guide.
class StepIllustration extends StatelessWidget {
  const StepIllustration({
    required this.icons,
    this.badge,
    this.connector = Icons.more_horiz,
    super.key,
  });

  final List<IconData> icons;
  final String? badge;
  final IconData connector;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < icons.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(connector, color: colors.outline, size: 32),
          ),
        );
      }
      children.add(
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: i.isEven
                ? colors.primaryContainer
                : colors.tertiaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icons[i],
            size: 48,
            color: i.isEven
                ? colors.onPrimaryContainer
                : colors.onTertiaryContainer,
          ),
        ),
      );
    }
    return Semantics(
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
          if (badge != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(badge!),
              backgroundColor: colors.secondaryContainer,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

/// Numbered step line ("1  Do this").
class NumberedStep extends StatelessWidget {
  const NumberedStep({required this.number, required this.text, super.key});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary,
            child: Text(
              '$number',
              style: TextStyle(color: colors.onPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class HintCard extends StatelessWidget {
  const HintCard({
    required this.text,
    this.icon = Icons.lightbulb_outline,
    this.title,
    this.warning = false,
    super.key,
  });

  final String text;
  final String? title;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = warning ? colors.errorContainer : colors.secondaryContainer;
    final fg = warning ? colors.onErrorContainer : colors.onSecondaryContainer;
    return Card(
      color: bg,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(text, style: TextStyle(color: fg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains a connection failure with title, what to do, firewall help when
/// relevant and the raw error hidden under "technical details".
class FailureCard extends StatelessWidget {
  const FailureCard({required this.failure, super.key});

  final ObsFailure failure;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = describeFailure(l, failure);
    final colors = Theme.of(context).colorScheme;
    final showFirewall =
        failure.kind == ObsFailureKind.timeout ||
        failure.kind == ObsFailureKind.serverOff;
    return Card(
      color: colors.errorContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: colors.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (text.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                text.hint!,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ],
            if (showFirewall)
              _Expandable(
                title: l.firewallHelpTitle,
                body: l.firewallHelpBody,
                color: colors.onErrorContainer,
              ),
            if (failure.detail != null)
              _Expandable(
                title: l.details,
                body: failure.detail!,
                color: colors.onErrorContainer,
                monospace: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _Expandable extends StatelessWidget {
  const _Expandable({
    required this.title,
    required this.body,
    required this.color,
    this.monospace = false,
  });

  final String title;
  final String body;
  final Color color;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: color,
        collapsedIconColor: color,
        title: Text(title, style: TextStyle(color: color)),
        children: [
          SelectableText(
            body,
            style: TextStyle(
              color: color,
              fontFamily: monospace ? 'monospace' : null,
              fontSize: monospace ? 12 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
