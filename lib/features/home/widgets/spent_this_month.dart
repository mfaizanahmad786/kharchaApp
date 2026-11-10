import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/rolling_amount.dart';
import '../../../core/widgets/bordered_card.dart';
import '../../../providers/providers.dart';

/// What the month has cost so far, against the same stretch of the month
/// before. One figure with its context beats two bare totals side by side.
class SpentThisMonth extends ConsumerWidget {
  const SpentThisMonth({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final spend = ref.watch(monthSpendProvider);
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return BorderedCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCurrentMonth
                ? 'Spent this month'
                : 'Spent in ${AppDate.monthYear(month)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: p.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RollingAmount(
              spend.value?.current ?? 0,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
              ),
              fractionOpacity: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Comparison(
            current: spend.value?.current ?? 0,
            previous: spend.value?.previous ?? 0,
            isCurrentMonth: isCurrentMonth,
          ),
        ],
      ),
    );
  }
}

/// The direction is carried by an arrow and by the words, not only by hue.
class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.current,
    required this.previous,
    required this.isCurrentMonth,
  });

  final int current;
  final int previous;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final baseline = isCurrentMonth
        ? 'than this time last month'
        : 'than the month before';

    if (previous == 0) {
      return Text(
        'Nothing to compare with last month',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.inkFaint,
        ),
      );
    }

    final difference = current - previous;
    if (difference == 0) {
      return Text(
        'Exactly level $baseline',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.inkSoft,
        ),
      );
    }

    final up = difference > 0;
    // Spending more is the direction worth noticing; spending less is good
    // news, so the two read differently rather than both as alarm.
    final tone = up ? p.expense : p.income;

    return Row(
      children: [
        Icon(
          up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 18,
          color: tone,
        ),
        const SizedBox(width: 6),
        AmountText(
          difference.abs(),
          showDecimals: false,
          color: tone,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          fractionOpacity: 1,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${up ? 'more' : 'less'} $baseline',
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
