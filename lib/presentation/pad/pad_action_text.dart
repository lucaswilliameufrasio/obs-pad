import '../../domain/pad/pad_models.dart';
import '../../l10n/app_localizations.dart';

String actionTypeLabel(AppLocalizations l, PadActionType type) =>
    switch (type) {
      PadActionType.switchScene => l.actionSwitchScene,
      PadActionType.toggleSource => l.actionToggleSource,
      PadActionType.toggleMute => l.actionToggleMute,
      PadActionType.toggleStream => l.actionToggleStream,
      PadActionType.startStream => l.actionStartStream,
      PadActionType.stopStream => l.actionStopStream,
      PadActionType.toggleRecord => l.actionToggleRecord,
      PadActionType.startRecord => l.actionStartRecord,
      PadActionType.stopRecord => l.actionStopRecord,
      PadActionType.toggleRecordPause => l.actionToggleRecordPause,
      PadActionType.saveReplay => l.actionSaveReplay,
      PadActionType.hotkey => l.actionHotkey,
      PadActionType.macro => l.actionMacro,
    };

/// One-line summary, e.g. "Trocar de cena: Jogo".
String describeAction(AppLocalizations l, PadAction action) {
  final label = actionTypeLabel(l, action.type);
  final detail = switch (action.type) {
    PadActionType.switchScene => action.sceneName,
    PadActionType.toggleSource => '${action.sourceName} (${action.sceneName})',
    PadActionType.toggleMute => action.inputName,
    PadActionType.hotkey => action.hotkeyName,
    PadActionType.macro => l.macroStepCount(action.steps.length),
    _ => null,
  };
  return detail == null ? label : '$label: $detail';
}

/// Text shown on the button while it is "on".
String? activeBadge(AppLocalizations l, PadActionType type) => switch (type) {
  PadActionType.switchScene => l.badgeOnAir,
  PadActionType.toggleSource => l.badgeVisible,
  PadActionType.toggleMute => l.badgeMuted,
  PadActionType.toggleStream ||
  PadActionType.startStream ||
  PadActionType.stopStream => l.badgeLive,
  PadActionType.toggleRecord ||
  PadActionType.startRecord ||
  PadActionType.stopRecord => l.badgeRecording,
  PadActionType.toggleRecordPause => l.badgePaused,
  PadActionType.saveReplay => l.badgeReady,
  PadActionType.hotkey || PadActionType.macro => null,
};
