import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obs_pad_companion/obs_pad_companion.dart';

import '../../l10n/app_localizations.dart';
import 'computer_helper.dart';

/// Searches the network for computers running OBS Pad Desktop and returns
/// the one the user picks.
Future<DiscoveredComputer?> showFindComputersSheet(BuildContext context) =>
    showModalBottomSheet<DiscoveredComputer>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _FindComputersSheet(),
    );

class _FindComputersSheet extends ConsumerStatefulWidget {
  const _FindComputersSheet();

  @override
  ConsumerState<_FindComputersSheet> createState() =>
      _FindComputersSheetState();
}

class _FindComputersSheetState extends ConsumerState<_FindComputersSheet> {
  List<DiscoveredComputer>? _found;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _found = null);
    List<DiscoveredComputer> found;
    try {
      found = await ref.read(computerFinderProvider)();
    } on Exception {
      found = const [];
    }
    if (mounted) setState(() => _found = found);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final found = _found;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.findTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (found == null) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(l.findSearching),
            ] else if (found.isEmpty) ...[
              Text(l.findNone, key: const Key('find-none')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh),
                label: Text(l.tryAgain),
              ),
            ] else
              for (final computer in found)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.computer),
                    title: Text(computer.announcement.name),
                    subtitle: Text(
                      computer.announcement.obsServerEnabled
                          ? computer.address
                          : '${computer.address}\n${l.findObsOff}',
                    ),
                    isThreeLine: !computer.announcement.obsServerEnabled,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(computer),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
