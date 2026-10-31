import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/bordered_card.dart';

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
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.info_outline,
                size: 15,
                color: AppColors.inkFaint,
              ),
            ],
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

/// The black pill under the money cards, lifted on a purple glow.
class InsightBanner extends StatelessWidget {
  const InsightBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: AppColors.ink,
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.insightBanner,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.purpleLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onDarkMuted,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.onDarkMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
