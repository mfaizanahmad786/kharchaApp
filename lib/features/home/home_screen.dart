import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/pills.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';
import '../shell/bottom_nav.dart';
import '../transaction/transaction_detail_screen.dart';
import '../transaction/transactions_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/money_summary.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/transaction_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  /// Flips the status-bar icons to dark once the purple header has scrolled past.
  bool _darkStatusBar = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final dark = _scroll.offset > 180;
    if (dark != _darkStatusBar) setState(() => _darkStatusBar = dark);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(monthTotalsProvider);
    final sections = ref.watch(groupedTransactionsProvider);
    final alerts = ref.watch(budgetAlertsProvider).value ?? const [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _darkStatusBar
          ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: RefreshIndicator(
          color: AppColors.purple,
          onRefresh: () async => ref.read(revisionProvider.notifier).bump(),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  onAvatarTap: () => ShellNavigator.of(context)?.go(3),
                  onBellTap: () => NotificationsSheet.show(context),
                ),
              ),

              // The white sheet is pulled up over the bottom of the header.
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.scaffold,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Your Money',
                          info: true,
                          trailing: DetailsChip(
                            label: 'Details',
                            onTap: () => ShellNavigator.of(context)?.go(1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: MoneySummaryCard(
                                label: 'Income',
                                amount: totals.value?.income ?? 0,
                                icon: Icons.savings_rounded,
                                color: AppColors.catBlue,
                                onTap: () => TransactionsScreen.open(context,
                                    initial: TxFilter.income),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: MoneySummaryCard(
                                label: 'Expenses',
                                amount: totals.value?.expense ?? 0,
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.expense,
                                onTap: () => TransactionsScreen.open(context,
                                    initial: TxFilter.expense),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InsightBanner(
                          message: alerts.isEmpty
                              ? 'Your insight is ready'
                              : '${alerts.length} budget${alerts.length == 1 ? '' : 's'} need attention',
                          actionLabel: alerts.isEmpty ? 'View' : 'Review',
                          onTap: () => alerts.isEmpty
                              ? ShellNavigator.of(context)?.go(1)
                              : ShellNavigator.of(context)?.go(2),
                        ),
                        const SizedBox(height: 24),
                        _TransactionsHeader(
                          onSeeAll: () => TransactionsScreen.open(context),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),

              ...switch (sections) {
                AsyncData(:final value) when value.isEmpty =>
                  const [SliverToBoxAdapter(child: _EmptyTransactions())],
                AsyncData(:final value) => _daySlivers(value),
                AsyncError() => const [
                    SliverToBoxAdapter(
                      child: _Message('Could not load your transactions.'),
                    )
                  ],
                _ => const [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.purple),
                        ),
                      ),
                    )
                  ],
              },

              const SliverToBoxAdapter(
                child: SizedBox(height: kNavBarScrollPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _daySlivers(List<DaySection> sections) {
    final out = <Widget>[];
    for (final section in sections) {
      out.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppDate.friendlyDay(section.day),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(width: 6),
              AmountText(
                section.net,
                showSign: true,
                showDecimals: false,
                color: section.net >= 0 ? AppColors.income : AppColors.ink,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ));
      out.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: section.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final view = section.items[i];
            return TransactionTile(
              view: view,
              onTap: () => TransactionDetailScreen.open(context, view.txn.id),
            );
          },
        ),
      ));
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }
    return out;
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        CircleIconButton(
          icon: Icons.push_pin_outlined,
          iconSize: 17,
          onTap: onSeeAll,
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.history_rounded,
          iconSize: 18,
          onTap: onSeeAll,
        ),
        const SizedBox(width: 8),
        TagPill(
          label: 'For the Period',
          background: AppColors.purpleSoft,
          foreground: AppColors.purpleDark,
          onTap: onSeeAll,
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 46, color: AppColors.inkFaint),
          SizedBox(height: 14),
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the + button to record your first\ntransaction for this month.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w500),
          ),
        ),
      );
}
