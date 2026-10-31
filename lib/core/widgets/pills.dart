import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final fg = foreground ?? AppColors.inkSoft;
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? AppColors.track,
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
    this.size = 34,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.shadows = AppColors.softShadow,
    this.badge = false,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color background;
  final Color foreground;
  final List<BoxShadow> shadows;
  final bool badge;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: background,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: shadows,
                  color: background,
                ),
                child: Icon(icon, size: iconSize ?? size * 0.5, color: foreground),
              ),
            ),
          ),
          if (badge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.expense,
                  shape: BoxShape.circle,
                  border: Border.all(color: background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
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
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (info) ...[
            const SizedBox(width: 6),
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.inkFaint),
          ],
          const Spacer(),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
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
    return LayoutBuilder(
      builder: (context, c) {
        final segW = c.maxWidth / labels.length;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.track,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: AppColors.softShadow,
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
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? AppColors.ink : AppColors.inkSoft,
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
