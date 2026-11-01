import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/bordered_card.dart';

/// Placeholder in the shape of the transaction list.
///
/// A spinner tells people only that something is happening; a skeleton tells
/// them what is coming and stops the layout jumping when it arrives.
class TransactionsSkeleton extends StatelessWidget {
  const TransactionsSkeleton({super.key, this.days = 2, this.rowsPerDay = 2});

  final int days;
  final int rowsPerDay;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var d = 0; d < days; d++) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  0,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const _Bar(width: 84, height: 15),
                    const Spacer(),
                    _Bar(width: 96, height: 15, tone: AppColors.track),
                  ],
                ),
              ),
              for (var i = 0; i < rowsPerDay; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const _SkeletonRow(),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return BorderedCard(
      padding: const EdgeInsets.all(14),
      shadow: false,
      child: Row(
        children: [
          Container(
            width: AppSizes.txnGlyph,
            height: AppSizes.txnGlyph,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: AppRadii.tileShape,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(width: 118, height: 17),
                SizedBox(height: 8),
                _Bar(width: 76, height: 13),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(width: 92, height: 16),
              SizedBox(height: 8),
              _Bar(width: 70, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    this.tone = AppColors.track,
  });

  final double width;
  final double height;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: tone,
      borderRadius: BorderRadius.circular(height / 3),
    ),
  );
}
