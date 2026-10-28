import 'package:flutter/material.dart';

/// Icons users can pick. Kept as a const map (instead of storing code points)
/// so release builds can tree-shake the icon font.
const Map<String, IconData> padIcons = {
  'star': Icons.star_rounded,
  'videocam': Icons.videocam_rounded,
  'live': Icons.sensors_rounded,
  'record': Icons.fiber_manual_record_rounded,
  'pause': Icons.pause_rounded,
  'play': Icons.play_arrow_rounded,
  'stop': Icons.stop_rounded,
  'replay': Icons.replay_30_rounded,
  'mic': Icons.mic_rounded,
  'mic_off': Icons.mic_off_rounded,
  'volume': Icons.volume_up_rounded,
  'volume_off': Icons.volume_off_rounded,
  'headset': Icons.headset_mic_rounded,
  'music_note': Icons.music_note_rounded,
  'camera': Icons.photo_camera_rounded,
  'screen': Icons.desktop_windows_rounded,
  'game': Icons.sports_esports_rounded,
  'chat': Icons.chat_rounded,
  'coffee': Icons.coffee_rounded,
  'bed': Icons.hotel_rounded,
  'image': Icons.image_rounded,
  'layers': Icons.layers_rounded,
  'visibility': Icons.visibility_rounded,
  'visibility_off': Icons.visibility_off_rounded,
  'bolt': Icons.bolt_rounded,
  'keyboard': Icons.keyboard_rounded,
  'auto': Icons.auto_awesome_rounded,
  'flag': Icons.flag_rounded,
  'heart': Icons.favorite_rounded,
  'thumb': Icons.thumb_up_rounded,
  'laugh': Icons.sentiment_very_satisfied_rounded,
  'celebration': Icons.celebration_rounded,
  'alarm': Icons.alarm_rounded,
  'timer': Icons.timer_rounded,
  'person': Icons.person_rounded,
  'group': Icons.groups_rounded,
  'home': Icons.home_rounded,
  'warning': Icons.warning_rounded,
  'lightbulb': Icons.lightbulb_rounded,
  'brush': Icons.brush_rounded,
  'movie': Icons.movie_rounded,
  'speaker': Icons.speaker_rounded,
};

IconData padIcon(String key) => padIcons[key] ?? Icons.star_rounded;

const List<int> padColors = [
  0xFF5B4BDB,
  0xFF1E88E5,
  0xFF00897B,
  0xFF43A047,
  0xFF7CB342,
  0xFFF9A825,
  0xFFFB8C00,
  0xFFE65100,
  0xFFE53935,
  0xFFD81B60,
  0xFF8E24AA,
  0xFF6D4C41,
  0xFF546E7A,
  0xFF212121,
];

const List<String> soundEmojis = [
  '🔊', '👏', '😂', '🥁', '🎺', '🎉', '💥', '🚨', '🔔', '📢', //
  '😱', '😮', '🤣', '👋', '❤️', '🔥', '⭐', '🎵', '🎶', '🐐', //
  '🦆', '🐱', '🐶', '👻', '💀', '🤖', '✅', '❌', '⏰', '🏆',
];

/// Readable text color on top of [background].
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black87;

class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in padIcons.entries)
          IconButton.outlined(
            isSelected: entry.key == selected,
            style: IconButton.styleFrom(
              backgroundColor: entry.key == selected
                  ? colors.primaryContainer
                  : null,
            ),
            icon: Icon(entry.value),
            onPressed: () => onSelected(entry.key),
          ),
      ],
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in padColors)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onSelected(value),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: value == selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: value == selected
                  ? Icon(Icons.check, color: onColor(Color(value)))
                  : null,
            ),
          ),
      ],
    );
  }
}
