import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/bordered_card.dart';
import '../../../core/theme/app_palette.dart';

/// The Income / Expenses pair under "Your Money". The amount is solid black:
/// unlike the balance in the header, nothing here is dimmed.
class MoneySummaryCard extends StatelessWidget {
  const MoneySummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.tint,
    required this.iconColor,
    this.onTap,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BorderedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.summaryGlyph,
            height: AppSizes.summaryGlyph,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: p.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          // A fixed line box: it keeps the two cards exactly the same height
          // without an IntrinsicHeight stretch, which left slack underneath.
          SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AmountText(
                amount,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
                // The reference keeps these numbers solid black end to end.
                fractionOpacity: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
