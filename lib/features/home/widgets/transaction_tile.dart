import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/bordered_card.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_palette.dart';

/// One row in the Transactions list: a tinted category tile, the title with
/// its account beneath, and the signed amount over the running balance.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, this.onTap});

  final TxnView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final txn = view.txn;
    final title = txn.note.isNotEmpty ? txn.note : view.category.name;

    return BorderedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: AppSizes.txnGlyph,
            height: AppSizes.txnGlyph,
            decoration: BoxDecoration(
              color: view.accent.withValues(alpha: 0.1),
              borderRadius: AppRadii.tileShape,
            ),
            child: Icon(view.category.icon, color: view.accent, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                _AccountLine(view: view),
                if (txn.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _TagLine(tags: txn.tags, accent: view.accent),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountText(
                txn.signed,
                color: view.amountColor(p),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                fractionOpacity: 1,
              ),
              const SizedBox(height: 4),
              AmountText(
                view.runningBalance,
                color: p.inkSoft,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                fractionOpacity: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "↳ ▣ Cash" — the return arrow, a small tinted account glyph, the name.
class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.view});

  final TxnView view;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(Icons.subdirectory_arrow_right, size: 14, color: p.inkFaint),
        const SizedBox(width: 5),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: view.account.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(view.account.icon, size: 11, color: view.account.color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            view.account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _TagLine extends StatelessWidget {
  const _TagLine({required this.tags, required this.accent});

  final List<String> tags;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tones = [AppColors.catBlue, p.income, AppColors.catAmber];
    return Row(
      children: [
        for (var i = 0; i < tags.length && i < 2; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Icon(
            i.isEven ? Icons.verified_rounded : Icons.person_rounded,
            size: 13,
            color: tones[i % tones.length],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tags[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.inkSoft,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Today ............ Total  -Rs2,451"
class DateGroupRow extends StatelessWidget {
  const DateGroupRow({super.key, required this.label, required this.net});

  final String label;
  final int net;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: p.inkSoft,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: p.inkSoft,
          ),
        ),
        const SizedBox(width: 6),
        AmountText(
          net,
          showSign: true,
          showDecimals: false,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
