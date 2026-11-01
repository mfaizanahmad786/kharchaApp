import 'package:flutter/material.dart';

import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glyph_tile.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/progress.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../data/repository/finance_repository.dart';
import '../../../core/theme/app_palette.dart';

/// One category row under the chart: share of total, amount, month-on-month
/// change, and a bar showing the share.
class CategoryBreakdownRow extends StatelessWidget {
  const CategoryBreakdownRow({
    super.key,
    required this.item,
    required this.total,
    this.onTap,
  });

  final CategoryTotal item;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final share = total == 0 ? 0.0 : item.total / total;
    final change = item.changePercent;

    return SoftCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
      shadows: p.softShadow,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphTile(
                icon: item.category.icon,
                color: item.category.color,
                size: 42,
                radius: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(share * 100).toStringAsFixed(share < 0.1 ? 1 : 0)}% of total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: p.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    item.total,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    fractionOpacity: 0.5,
                  ),
                  const SizedBox(height: 5),
                  if (change != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TagPill(
                          dense: true,
                          label:
                              '${change > 0
                                  ? '+'
                                  : change < 0
                                  ? '-'
                                  : ''}'
                              '${change.abs().toStringAsFixed(0)}%',
                          // Spending more than last month is the bad direction.
                          background: switch (change) {
                            > 0.5 => p.badgeRedBg,
                            < -0.5 => p.badgeGreenBg,
                            _ => p.track,
                          },
                          foreground: switch (change) {
                            > 0.5 => p.badgeRedFg,
                            < -0.5 => p.badgeGreenFg,
                            _ => p.inkSoft,
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'vs last month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.inkFaint,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'new this month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.inkFaint,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressTrack(value: share, color: item.category.color, height: 7),
        ],
      ),
    );
  }
}
