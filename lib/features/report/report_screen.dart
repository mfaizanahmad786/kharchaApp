import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/month_picker_sheet.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/models.dart';
import '../../data/repository/finance_repository.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';
import '../shell/bottom_nav.dart';
import 'widgets/category_breakdown_row.dart';
import 'widgets/donut_chart.dart';
import 'widgets/spend_bar_chart.dart';

enum _ChartMode { bars, donut }

/// How many categories get their own slice before the rest are grouped.
const _kMaxSlices = 5;

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  TxType _type = TxType.expense;
  _ChartMode _mode = _ChartMode.donut;

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(breakdownProvider(_type)).value ?? const <CategoryTotal>[];
    final daily = ref.watch(dailySeriesProvider(_type)).value ?? const [];
    final total = breakdown.fold<int>(0, (s, e) => s + e.total);
    final isExpense = _type.isExpense;
    final word = isExpense ? 'Expenses' : 'Income';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                      onPressed: () => ShellNavigator.of(context)?.go(0),
                    ),
                    Text('Report', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    const MonthPill(onLight: true),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: SegmentedToggle(
                  labels: const ['Expenses', 'Income'],
                  index: isExpense ? 0 : 1,
                  onChanged: (i) =>
                      setState(() => _type = i == 0 ? TxType.expense : TxType.income),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Text('$word Report',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    _ChartModeToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _mode == _ChartMode.donut
                      ? DonutChart(
                          key: ValueKey('donut-$_type-${breakdown.length}'),
                          slices: _buildSlices(breakdown, total),
                          centerLabel: 'Total $word',
                          centerValue: AmountText(
                            total,
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            fractionOpacity: 0.45,
                          ),
                        )
                      : SpendBarChart(
                          key: ValueKey('bars-$_type'),
                          data: daily,
                          color: isExpense ? AppColors.purple : AppColors.income,
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'All $word',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const Spacer(),
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
                      total,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                      fractionOpacity: 0.45,
                    ),
                  ],
                ),
              ),
            ),
            if (breakdown.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Center(
                    child: Text(
                      'Nothing recorded for this month yet.',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: breakdown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => CategoryBreakdownRow(
                    item: breakdown[i],
                    total: total,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: kNavBarScrollPadding),
            ),
          ],
        ),
      ),
    );
  }

  /// Top categories keep their own slice; the tail is folded into a single
  /// hatched "Other" wedge so the ring stays legible.
  List<DonutSlice> _buildSlices(List<CategoryTotal> items, int total) {
    if (items.isEmpty) return const [];
    final head = items.take(_kMaxSlices).toList();
    final tail = items.skip(_kMaxSlices);
    final slices = [
      for (final i in head)
        DonutSlice(
          label: i.category.name,
          value: i.total.toDouble(),
          color: i.category.color,
        ),
    ];
    final rest = tail.fold<int>(0, (s, e) => s + e.total);
    if (rest > 0) {
      slices.add(DonutSlice(
        label: 'Other (${tail.length})',
        value: rest.toDouble(),
        color: AppColors.inkFaint,
        hatched: true,
      ));
    }
    return slices;
  }
}

/// The two-icon bar/donut switch on the right of the section title.
class _ChartModeToggle extends StatelessWidget {
  const _ChartModeToggle({required this.mode, required this.onChanged});

  final _ChartMode mode;
  final ValueChanged<_ChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.bar_chart_rounded, _ChartMode.bars),
          const SizedBox(width: 4),
          _button(Icons.pie_chart_rounded, _ChartMode.donut),
        ],
      ),
    );
  }

  Widget _button(IconData icon, _ChartMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: selected ? Colors.white : AppColors.inkFaint,
        ),
      ),
    );
  }
}
