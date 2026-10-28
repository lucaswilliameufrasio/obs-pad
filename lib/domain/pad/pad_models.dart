import '../../core/json.dart';

enum PadActionType {
  switchScene,
  toggleSource,
  toggleMute,
  toggleStream,
  startStream,
  stopStream,
  toggleRecord,
  startRecord,
  stopRecord,
  toggleRecordPause,
  saveReplay,
  hotkey,
  macro;

  static PadActionType parse(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? switchScene;

  bool get needsScene => this == switchScene || this == toggleSource;
  bool get needsSource => this == toggleSource;
  bool get needsInput => this == toggleMute;
  bool get needsHotkey => this == hotkey;
}

/// What a button does. Sources are referenced by name (not id) so a button
/// keeps working when OBS re-creates the scene item.
class PadAction {
  const PadAction({
    required this.type,
    this.sceneName,
    this.sourceName,
    this.inputName,
    this.hotkeyName,
    this.steps = const [],
  });

  factory PadAction.fromJson(JsonMap json) => PadAction(
    type: PadActionType.parse(json.strOrNull('type')),
    sceneName: json.strOrNull('scene'),
    sourceName: json.strOrNull('source'),
    inputName: json.strOrNull('input'),
    hotkeyName: json.strOrNull('hotkey'),
    steps: json.objects('steps').map(MacroStep.fromJson).toList(),
  );

  final PadActionType type;
  final String? sceneName;
  final String? sourceName;
  final String? inputName;
  final String? hotkeyName;

  /// Only for [PadActionType.macro].
  final List<MacroStep> steps;

  JsonMap toJson() => {
    'type': type.name,
    'scene': ?sceneName,
    'source': ?sourceName,
    'input': ?inputName,
    'hotkey': ?hotkeyName,
    if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
  };

  /// True when every field the action type needs is filled.
  bool get isComplete => switch (type) {
    PadActionType.switchScene => sceneName?.isNotEmpty ?? false,
    PadActionType.toggleSource =>
      (sceneName?.isNotEmpty ?? false) && (sourceName?.isNotEmpty ?? false),
    PadActionType.toggleMute => inputName?.isNotEmpty ?? false,
    PadActionType.hotkey => hotkeyName?.isNotEmpty ?? false,
    PadActionType.macro =>
      steps.isNotEmpty && steps.every((s) => s.action.isComplete),
    _ => true,
  };
}

/// One step of a macro: run [action], then wait [delayMs] before the next.
class MacroStep {
  const MacroStep({required this.action, this.delayMs = 0});

  factory MacroStep.fromJson(JsonMap json) => MacroStep(
    action: PadAction.fromJson(json.object('action') ?? const {}),
    delayMs: json.integer('delayMs'),
  );

  final PadAction action;
  final int delayMs;

  JsonMap toJson() => {'action': action.toJson(), 'delayMs': delayMs};

  MacroStep copyWith({PadAction? action, int? delayMs}) => MacroStep(
    action: action ?? this.action,
    delayMs: delayMs ?? this.delayMs,
  );
}

enum PadButtonSize {
  small,
  medium,
  large;

  static PadButtonSize parse(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? medium;

  double get scale => switch (this) {
    small => 0.8,
    medium => 1,
    large => 1.3,
  };
}

class PadButton {
  const PadButton({
    required this.id,
    required this.label,
    required this.action,
    this.icon = 'star',
    this.color = 0xFF5B4BDB,
    this.size = PadButtonSize.medium,
  });

  factory PadButton.fromJson(JsonMap json) => PadButton(
    id: json.str('id'),
    label: json.str('label'),
    icon: json.str('icon', 'star'),
    color: json.integer('color', 0xFF5B4BDB),
    size: PadButtonSize.parse(json.strOrNull('size')),
    action: PadAction.fromJson(json.object('action') ?? const {}),
  );

  final String id;
  final String label;
  final String icon;

  /// ARGB.
  final int color;
  final PadButtonSize size;
  final PadAction action;

  JsonMap toJson() => {
    'id': id,
    'label': label,
    'icon': icon,
    'color': color,
    'size': size.name,
    'action': action.toJson(),
  };

  PadButton copyWith({
    String? label,
    String? icon,
    int? color,
    PadButtonSize? size,
    PadAction? action,
  }) => PadButton(
    id: id,
    label: label ?? this.label,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    size: size ?? this.size,
    action: action ?? this.action,
  );
}

class PadLayout {
  const PadLayout({
    required this.id,
    required this.name,
    this.columns = 3,
    this.buttons = const [],
  });

  factory PadLayout.fromJson(JsonMap json) => PadLayout(
    id: json.str('id'),
    name: json.str('name'),
    columns: json.integer('columns', 3).clamp(2, 6),
    buttons: json.objects('buttons').map(PadButton.fromJson).toList(),
  );

  final String id;
  final String name;
  final int columns;
  final List<PadButton> buttons;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'columns': columns,
    'buttons': buttons.map((b) => b.toJson()).toList(),
  };

  PadLayout copyWith({String? name, int? columns, List<PadButton>? buttons}) =>
      PadLayout(
        id: id,
        name: name ?? this.name,
        columns: columns ?? this.columns,
        buttons: buttons ?? this.buttons,
      );
}
