import 'package:flutter/material.dart';

import '../domain/obs_failure.dart';
import '../l10n/app_localizations.dart';

/// Human title + "what to do" for a failure.
class FailureText {
  const FailureText(this.title, [this.hint]);
  final String title;
  final String? hint;

  /// Single line for snackbars.
  String get message => hint == null ? title : '$title. $hint';
}

FailureText describeFailure(AppLocalizations l, Object error) {
  final failure = error is ObsFailure
      ? error
      : ObsFailure(ObsFailureKind.unknown, detail: error.toString());
  final name = failure.resource;
  return switch (failure.kind) {
    ObsFailureKind.wrongPassword => FailureText(
      l.failWrongPasswordTitle,
      l.failWrongPasswordHint,
    ),
    ObsFailureKind.serverOff => FailureText(
      l.failServerOffTitle,
      l.failServerOffHint,
    ),
    ObsFailureKind.timeout => FailureText(
      l.failTimeoutTitle,
      l.failTimeoutHint,
    ),
    ObsFailureKind.unreachable => FailureText(
      l.failUnreachableTitle,
      l.failUnreachableHint,
    ),
    ObsFailureKind.invalidAddress => FailureText(
      l.failInvalidAddressTitle,
      l.failInvalidAddressHint,
    ),
    ObsFailureKind.notObs => FailureText(l.failNotObsTitle, l.failNotObsHint),
    ObsFailureKind.unsupportedVersion => FailureText(
      l.failUnsupportedTitle,
      l.failUnsupportedHint,
    ),
    ObsFailureKind.notConnected => FailureText(
      l.failNotConnectedTitle,
      l.failNotConnectedHint,
    ),
    ObsFailureKind.resourceNotFound => FailureText(
      name == null ? l.failNotFound : l.failNotFoundNamed(name),
      l.failNotFoundHint,
    ),
    ObsFailureKind.alreadyExists => FailureText(l.failAlreadyExists),
    ObsFailureKind.outputAlreadyActive => FailureText(l.failOutputActive),
    ObsFailureKind.outputNotActive => FailureText(l.failOutputNotActive),
    ObsFailureKind.recordPauseUnsupported => FailureText(
      l.failRecordPauseTitle,
      l.failRecordPauseHint,
    ),
    ObsFailureKind.replayBufferOff => FailureText(
      l.failReplayOffTitle,
      l.failReplayOffHint,
    ),
    ObsFailureKind.outputDisabled => FailureText(
      l.failOutputDisabledTitle,
      l.failOutputDisabledHint,
    ),
    ObsFailureKind.invalidState => FailureText(
      name == null ? l.failInvalidState : l.failInvalidStateNamed(name),
    ),
    ObsFailureKind.invalidInputKind => FailureText(l.failInvalidInputKind),
    ObsFailureKind.requestFailed => FailureText(l.failRequestFailed),
    ObsFailureKind.unknown => FailureText(l.failUnknown),
  };
}

/// Shows an OBS error as a friendly snackbar.
void showFailureSnack(BuildContext context, Object error) {
  final text = describeFailure(AppLocalizations.of(context), error);
  final colors = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text.message,
          style: TextStyle(color: colors.onErrorContainer),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.errorContainer,
        showCloseIcon: true,
        closeIconColor: colors.onErrorContainer,
      ),
    );
}

/// Runs an OBS command and shows a snackbar if it fails.
Future<bool> runObs(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on Exception catch (error) {
    if (context.mounted) showFailureSnack(context, error);
    return false;
  }
}
