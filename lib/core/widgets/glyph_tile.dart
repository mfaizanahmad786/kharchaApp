import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The tinted rounded-square icon that fronts every category, account,
/// budget and goal row.
class GlyphTile extends StatelessWidget {
  const GlyphTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.radius = 14,
    this.iconSize,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double radius;
  final double? iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: circle ? null : BorderRadius.circular(radius),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }
}
