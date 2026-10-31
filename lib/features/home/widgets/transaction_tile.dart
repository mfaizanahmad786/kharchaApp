import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glyph_tile.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../data/models/models.dart';

/// One row in the Transactions list: glyph, category, account + tags on the
/// left; signed amount over the running balance on the right.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, this.onTap});

  final TxnView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final txn = view.txn;
    final title = txn.note.isNotEmpty ? txn.note : view.category.name;

    return SoftCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      shadows: AppColors.softShadow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlyphTile(icon: view.category.icon, color: view.accent),
          const SizedBox(width: 12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                _Subtitle(view: view),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountText(
                txn.signed,
                color: view.amountColor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                fractionOpacity: 0.75,
              ),
              const SizedBox(height: 3),
              AmountText(
                view.runningBalance,
                color: AppColors.inkFaint,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                fractionOpacity: 0.7,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.view});

  final TxnView view;

  @override
  Widget build(BuildContext context) {
    final tags = view.txn.tags;
    return Row(
      children: [
        const Icon(
          Icons.subdirectory_arrow_right_rounded,
          size: 13,
          color: AppColors.inkFaint,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            view.account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(Icons.local_offer_rounded, size: 11, color: view.accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              tags.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
