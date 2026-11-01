import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_palette.dart';

/// Small rounded label — "+12%", "Vacation", "For the Period".
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
    this.dense = false,
    this.onTap,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = foreground ?? p.inkSoft;
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? p.track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }
}

/// Circular icon button on a light surface — the pin / history / share buttons.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = AppSizes.circleButton,
    this.background,
    this.foreground,
    this.shadows,
    this.badge = false,
    this.iconSize,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// The drawn circle. The tappable area is always at least [AppSizes.hitArea].
  final double size;
  final Color? background;
  final Color? foreground;
  final List<BoxShadow>? shadows;
  final bool badge;
  final double? iconSize;

  /// Read aloud by TalkBack and shown on long press. An icon with no label is
  /// invisible to a screen reader.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hit = size < AppSizes.hitArea ? AppSizes.hitArea : size;
    final bg = background ?? p.surface;
    final fg = foreground ?? p.ink;
    final shade = shadows ?? p.softShadow;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: shade,
        color: bg,
        border: bg == p.surface ? Border.all(color: p.border) : null,
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: fg),
    );

    if (badge) {
      circle = Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: size * 0.13,
            top: size * 0.13,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: p.expense,
                shape: BoxShape.circle,
                border: Border.all(color: bg, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    // The ink responds across the full hit area, not just the drawn circle.
    Widget button = SizedBox(
      width: hit,
      height: hit,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: circle),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// "Section title ............ action" header row.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.trailingLabel,
    this.info = false,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final String? trailingLabel;
  final bool info;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (info) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.info_outline_rounded, size: 16, color: p.inkFaint),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (trailing != null)
            trailing!
          else if (trailingLabel != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  trailingLabel!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.inkSoft,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two-up segmented control — "Expenses | Income".
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 50,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final segW = c.maxWidth / labels.length;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: p.track,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: p.softShadow,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(i),
                        borderRadius: BorderRadius.circular(height / 2),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: 15,
                              fontWeight: i == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == index ? p.ink : p.inkSoft,
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
