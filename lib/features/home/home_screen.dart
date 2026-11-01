import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/bordered_card.dart';
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
import 'widgets/transactions_skeleton.dart';
import '../../core/theme/app_palette.dart';

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
    final dark = _scroll.offset > 200;
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
    final p = context.palette;
    final totals = ref.watch(monthTotalsProvider);
    final sections = ref.watch(groupedTransactionsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _darkStatusBar
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: p.surface,
        body: RefreshIndicator(
          color: AppColors.brand,
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

              SliverToBoxAdapter(
                child: ColoredBox(
                  color: p.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.xs,
                      AppSpacing.screen,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeading(
                          title: 'Your Money',
                          trailing: OutlinedPill(
                            label: 'Details',
                            onTap: () => ShellNavigator.of(context)?.go(1),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: MoneySummaryCard(
                                label: 'In',
                                amount: totals.value?.income ?? 0,
                                icon: Icons.savings_rounded,
                                tint: p.incomeTint,
                                iconColor: AppColors.catBlue,
                                onTap: () => TransactionsScreen.open(
                                  context,
                                  initial: TxFilter.income,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.cardGap),
                            Expanded(
                              child: MoneySummaryCard(
                                label: 'Out',
                                amount: totals.value?.expense ?? 0,
                                icon: Icons.account_balance_wallet_rounded,
                                tint: p.expenseTint,
                                iconColor: p.expense,
                                onTap: () => TransactionsScreen.open(
                                  context,
                                  initial: TxFilter.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _TransactionsHeader(
                          onSeeAll: () => TransactionsScreen.open(context),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),

              ...switch (sections) {
                AsyncData(:final value) when value.isEmpty => const [
                  SliverToBoxAdapter(child: _EmptyTransactions()),
                ],
                AsyncData(:final value) => _daySlivers(value),
                AsyncError() => const [
                  SliverToBoxAdapter(
                    child: _Message('Could not load your transactions.'),
                  ),
                ],
                _ => const [SliverToBoxAdapter(child: TransactionsSkeleton())],
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
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: DateGroupRow(
              label: AppDate.friendlyDay(section.day),
              net: section.net,
            ),
          ),
        ),
      );
      out.add(
        SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList.separated(
            itemCount: section.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final view = section.items[i];
              return TransactionTile(
                view: view,
                onTap: () => TransactionDetailScreen.open(context, view.txn.id),
              );
            },
          ),
        ),
      );
      out.add(const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)));
    }
    return out;
  }
}

/// A 20px bold section title, optionally with the small info glyph.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Transactions',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // One control, one behaviour. The pin icon did exactly what this does
        // and the chip looked like a filter while only navigating.
        CircleIconButton(
          icon: Icons.history_rounded,
          iconSize: 17,
          tooltip: 'All transactions',
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
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xl,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 46, color: p.inkFaint),
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
              color: p.inkSoft,
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
        style: TextStyle(
          color: context.palette.inkSoft,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
