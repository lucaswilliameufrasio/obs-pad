import '../../core/json.dart';

enum SoundPlayMode {
  /// Tap plays from the start until the end; tap again stops.
  playToEnd,

  /// Plays only while the finger is on the pad.
  holdToPlay;

  static SoundPlayMode parse(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? playToEnd;
}

/// Lower another input (mic, music) while this sound plays.
class DuckingConfig {
  const DuckingConfig({required this.inputName, this.reductionDb = 15});

  factory DuckingConfig.fromJson(JsonMap json) => DuckingConfig(
    inputName: json.str('input'),
    reductionDb: json.number('reductionDb', 15),
  );

  final String inputName;

  /// How many dB to lower the target (positive number).
  final double reductionDb;

  JsonMap toJson() => {'input': inputName, 'reductionDb': reductionDb};
}

class SoundPad {
  const SoundPad({
    required this.id,
    required this.label,
    required this.inputName,
    this.emoji,
    this.icon = 'music_note',
    this.color = 0xFFE65100,
    this.mode = SoundPlayMode.playToEnd,
    this.volumeMul,
    this.loop = false,
    this.ducking,
  });

  factory SoundPad.fromJson(JsonMap json) {
    final ducking = json.object('ducking');
    return SoundPad(
      id: json.str('id'),
      label: json.str('label'),
      inputName: json.str('input'),
      emoji: json.strOrNull('emoji'),
      icon: json.str('icon', 'music_note'),
      color: json.integer('color', 0xFFE65100),
      mode: SoundPlayMode.parse(json.strOrNull('mode')),
      volumeMul: json['volume'] is num ? json.number('volume') : null,
      loop: json.boolean('loop'),
      ducking: ducking == null ? null : DuckingConfig.fromJson(ducking),
    );
  }

  final String id;
  final String label;

  /// Media Source in OBS that this pad triggers.
  final String inputName;

  /// Shown instead of [icon] when set.
  final String? emoji;
  final String icon;
  final int color;
  final SoundPlayMode mode;

  /// null = leave the OBS volume untouched.
  final double? volumeMul;
  final bool loop;
  final DuckingConfig? ducking;

  JsonMap toJson() => {
    'id': id,
    'label': label,
    'input': inputName,
    'emoji': ?emoji,
    'icon': icon,
    'color': color,
    'mode': mode.name,
    'volume': ?volumeMul,
    'loop': loop,
    if (ducking != null) 'ducking': ducking!.toJson(),
  };

  SoundPad copyWith({
    String? label,
    String? inputName,
    String? Function()? emoji,
    String? icon,
    int? color,
    SoundPlayMode? mode,
    double? Function()? volumeMul,
    bool? loop,
    DuckingConfig? Function()? ducking,
  }) => SoundPad(
    id: id,
    label: label ?? this.label,
    inputName: inputName ?? this.inputName,
    emoji: emoji != null ? emoji() : this.emoji,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    mode: mode ?? this.mode,
    volumeMul: volumeMul != null ? volumeMul() : this.volumeMul,
    loop: loop ?? this.loop,
    ducking: ducking != null ? ducking() : this.ducking,
  );
}

/// A page (or folder) of pads.
class SoundPage {
  const SoundPage({required this.id, required this.name, this.pads = const []});

  factory SoundPage.fromJson(JsonMap json) => SoundPage(
    id: json.str('id'),
    name: json.str('name'),
    pads: json.objects('pads').map(SoundPad.fromJson).toList(),
  );

  final String id;
  final String name;
  final List<SoundPad> pads;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'pads': pads.map((p) => p.toJson()).toList(),
  };

  SoundPage copyWith({String? name, List<SoundPad>? pads}) =>
      SoundPage(id: id, name: name ?? this.name, pads: pads ?? this.pads);
}

class SoundboardProfile {
  const SoundboardProfile({
    required this.id,
    required this.name,
    this.pages = const [],
  });

  factory SoundboardProfile.fromJson(JsonMap json) => SoundboardProfile(
    id: json.str('id'),
    name: json.str('name'),
    pages: json.objects('pages').map(SoundPage.fromJson).toList(),
  );

  final String id;
  final String name;
  final List<SoundPage> pages;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  SoundboardProfile copyWith({String? name, List<SoundPage>? pages}) =>
      SoundboardProfile(
        id: id,
        name: name ?? this.name,
        pages: pages ?? this.pages,
      );

  Iterable<SoundPad> get allPads => pages.expand((p) => p.pads);
}
