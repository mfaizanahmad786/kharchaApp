import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/glyph_tile.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'add_transaction_sheet.dart';

final _detailProvider = FutureProvider.family<TxnView?, String>((
  ref,
  id,
) async {
  ref.watch(revisionProvider);
  final repo = ref.watch(repositoryProvider);
  final txn = await repo.transactionById(id);
  if (txn == null) return null;
  final views = await repo.hydrate([txn]);
  return views.isEmpty ? null : views.first;
});

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  static Future<void> open(BuildContext context, String id) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => TransactionDetailScreen(id: id)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(_detailProvider(id)).value;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Transaction'),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      body: view == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : _Body(view: view),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.view});

  final TxnView view;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(actionsProvider).deleteTransaction(view.txn.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txn = view.txn;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Column(
            children: [
              GlyphTile(
                icon: view.category.icon,
                color: view.accent,
                size: 72,
                radius: 24,
                iconSize: 32,
              ),
              const SizedBox(height: 16),
              AmountText(
                txn.signed,
                showSign: true,
                color: view.amountColor,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                ),
                fractionOpacity: 0.55,
              ),
              const SizedBox(height: 8),
              TagPill(
                label: txn.type.isIncome ? 'Income' : 'Expense',
                background: AppColors.tint(view.amountColor),
                foreground: view.amountColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _Row(
                label: 'Category',
                value: view.category.name,
                icon: view.category.icon,
              ),
              const Divider(),
              _Row(
                label: 'Account',
                value: view.account.name,
                icon: view.account.icon,
              ),
              const Divider(),
              _Row(
                label: 'Date',
                value: AppDate.fullDay(txn.date),
                icon: Icons.calendar_today_rounded,
              ),
              const Divider(),
              _Row(
                label: 'Time',
                value: AppDate.time(txn.date),
                icon: Icons.schedule_rounded,
              ),
              if (txn.note.isNotEmpty) ...[
                const Divider(),
                _Row(label: 'Note', value: txn.note, icon: Icons.notes_rounded),
              ],
              const Divider(),
              _Row(
                label: 'Balance after',
                value: '',
                icon: Icons.account_balance_wallet_rounded,
                trailing: AmountText(
                  view.runningBalance,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (txn.tags.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in txn.tags)
                TagPill(
                  label: t,
                  icon: Icons.local_offer_rounded,
                  background: AppColors.purpleSoft,
                  foreground: AppColors.purpleDark,
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(
                      color: AppColors.badgeRedBg,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () =>
                      AddTransactionSheet.show(context, existing: txn),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkFaint),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing!
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
