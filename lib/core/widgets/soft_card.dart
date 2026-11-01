import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// White card with the soft, wide shadow used throughout the design.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color,
    this.onTap,
    this.shadows,
    this.border,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final BoxBorder? border;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    final fill = color ?? p.surface;
    final shade = shadows ?? p.cardShadow;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: shape,
        boxShadow: shade,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
