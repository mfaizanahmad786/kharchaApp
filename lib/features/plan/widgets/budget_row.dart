import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glyph_tile.dart';
import '../../../core/widgets/progress.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../data/repository/finance_repository.dart';

/// Budget row: glyph, name, spent-of-limit, and a ring that turns amber near
/// the threshold and red once the limit is passed.
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.status, this.onTap});

  final BudgetStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = status.budget;
    final tone = status.isOver
        ? AppColors.expense
        : status.isNearLimit
            ? AppColors.warning
            : b.color;

    return SoftCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Row(
        children: [
          GlyphTile(icon: b.icon, color: tone, size: 48, radius: 16),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AmountText(
                      status.spent,
                      showDecimals: false,
                      color: status.isOver ? AppColors.expense : AppColors.ink,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      ' of ',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    AmountText(
                      b.limit,
                      showDecimals: false,
                      color: AppColors.inkSoft,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          RingProgress(
            value: status.progress,
            color: tone,
            size: 54,
            label: '${(status.rawProgress * 100).round()}%',
          ),
        ],
      ),
    );
  }
}
