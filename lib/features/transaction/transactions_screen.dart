import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/month_picker_sheet.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../home/widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_palette.dart';

enum TxFilter {
  all('All'),
  expense('Out'),
  income('In');

  const TxFilter(this.label);
  final String label;

  TxType? get type => switch (this) {
    TxFilter.all => null,
    TxFilter.expense => TxType.expense,
    TxFilter.income => TxType.income,
  };
}

/// The full, searchable transaction list for the selected month.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.initial = TxFilter.all});

  final TxFilter initial;

  static Future<void> open(
    BuildContext context, {
    TxFilter initial = TxFilter.all,
  }) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TransactionsScreen(initial: initial)),
  );

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late TxFilter _filter = widget.initial;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TxnView> _apply(List<TxnView> all) {
    final q = _query.trim().toLowerCase();
    return all
        .where((v) {
          if (_filter.type != null && v.txn.type != _filter.type) return false;
          if (q.isEmpty) return true;
          return v.category.name.toLowerCase().contains(q) ||
              v.account.name.toLowerCase().contains(q) ||
              v.txn.note.toLowerCase().contains(q) ||
              v.txn.tags.any((t) => t.toLowerCase().contains(q));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final all = ref.watch(monthTransactionsProvider).value ?? const <TxnView>[];
    final items = _apply(all);
    final total = items.fold<int>(0, (s, v) => s + v.txn.signed);

    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: p.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Transactions'),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: MonthPill(onLight: true)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: p.softShadow,
              ),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search category, account or note',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.inkFaint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: p.inkFaint,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: p.inkFaint,
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedToggle(
              labels: TxFilter.values.map((f) => f.label).toList(),
              index: TxFilter.values.indexOf(_filter),
              height: 46,
              onChanged: (i) => setState(() => _filter = TxFilter.values[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text(
                  '${items.length} transaction${items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.inkSoft,
                  ),
                ),
                const Spacer(),
                Text(
                  'Net',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(width: 6),
                AmountText(
                  total,
                  showSign: true,
                  showDecimals: false,
                  color: total >= 0 ? p.income : p.expense,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Nothing matches that.',
                      style: TextStyle(
                        color: p.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: items.length,
                    separatorBuilder: (context, i) {
                      final prev = items[i].txn.date;
                      final next = items[i + 1].txn.date;
                      if (AppDate.sameDay(prev, next)) {
                        return const SizedBox(height: 10);
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                        child: Text(
                          AppDate.friendlyDay(next),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.inkSoft,
                          ),
                        ),
                      );
                    },
                    itemBuilder: (context, i) => TransactionTile(
                      view: items[i],
                      onTap: () => TransactionDetailScreen.open(
                        context,
                        items[i].txn.id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
