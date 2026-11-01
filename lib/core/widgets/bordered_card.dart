import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// The white card used across Home: a hairline border instead of a shadow.
/// Shared so the radius, border colour and ink response are decided once.
class BorderedCard extends StatelessWidget {
  const BorderedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.card,
    this.borderColor,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to the palette border for the current appearance.
  final Color? borderColor;
  final VoidCallback? onTap;

  /// A very faint lift. The border does the work; this only stops the card
  /// from looking pasted onto the sheet.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    final edge = borderColor ?? p.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: shape,
        border: Border.all(color: edge),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x08101828),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A transparent, outlined pill — "Details ›". Never a filled white button.
class OutlinedPill extends StatelessWidget {
  const OutlinedPill({
    super.key,
    required this.label,
    this.onTap,
    this.trailing = Icons.chevron_right_rounded,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: p.borderSoft)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            9,
            trailing == null ? AppSpacing.lg : 10,
            9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.inkSoft,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 18, color: p.inkSoft),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
