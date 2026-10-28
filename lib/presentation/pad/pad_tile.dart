import 'package:flutter/material.dart';

import '../widgets/catalog.dart';

/// Visual of a pad / sound button: tonal when off, solid and glowing when on.
class PadTile extends StatelessWidget {
  const PadTile({
    required this.label,
    required this.color,
    this.icon,
    this.emoji,
    this.active = false,
    this.badge,
    this.busy = false,
    this.scale = 1,
    this.editing = false,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final String? emoji;
  final bool active;

  /// Small status text, e.g. "NO AR" or "MUTADO".
  final String? badge;
  final bool busy;
  final double scale;
  final bool editing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = active
        ? color
        : Color.alphaBlend(
            color.withValues(
              alpha: brightness == Brightness.dark ? 0.28 : 0.18,
            ),
            Theme.of(context).colorScheme.surface,
          );
    final foreground = active
        ? onColor(color)
        : (brightness == Brightness.dark ? Colors.white : color);

    return Semantics(
      button: true,
      toggled: badge != null ? active : null,
      label: badge == null ? label : '$label, $badge',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? onColor(color).withValues(alpha: 0.6)
                : color.withValues(alpha: 0.5),
            width: active ? 3 : 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            onLongPress: onLongPress,
            onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
            onTapUp: onTapUp == null ? null : (_) => onTapUp!(),
            onTapCancel: onTapUp,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emoji != null && emoji!.isNotEmpty)
                          Text(emoji!, style: TextStyle(fontSize: 30 * scale))
                        else if (icon != null)
                          Icon(icon, size: 34 * scale, color: foreground),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (badge != null && active)
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: foreground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: background,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (busy)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    ),
                  ),
                if (editing)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: foreground,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
