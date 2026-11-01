import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/models.dart';
import '../../data/repository/finance_repository.dart';
import '../../providers/providers.dart';
import '../shell/bottom_nav.dart';
import 'edit_budget_sheet.dart';
import 'edit_goal_sheet.dart';
import 'plan_list_screens.dart';
import 'widgets/budget_row.dart';
import 'widgets/goal_card.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/text_prompt_dialog.dart';

/// Goals (savings targets) on top, budgets (monthly spending ceilings) below.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static const _goalPreview = 1;
  static const _budgetPreview = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final budgets =
        ref.watch(budgetStatusesProvider).value ?? const <BudgetStatus>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: p.scaffold,
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
                      Text(
                        'My Plan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      CircleIconButton(
                        icon: Icons.add_rounded,
                        size: 44,
                        iconSize: 23,
                        background: p.ink,
                        foreground: p.surface,
                        tooltip: 'New goal or budget',
                        onTap: () => _showAddMenu(context),
                      ),
                      const SizedBox(width: 10),
                      CircleIconButton(
                        icon: Icons.north_east_rounded,
                        size: 44,
                        iconSize: 19,
                        tooltip: 'All goals',
                        onTap: () => GoalsScreen.open(context),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Goals
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: SectionHeader(
                    title: 'Goals',
                    trailingLabel: 'View All',
                    onTrailingTap: () => GoalsScreen.open(context),
                  ),
                ),
              ),
              if (goals.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyBlock(
                    icon: Icons.flag_rounded,
                    title: 'No goals yet',
                    body:
                        'Set a savings target and Kharcha will track whether you are on schedule.',
                    actionLabel: 'Add a goal',
                    onAction: () => EditGoalSheet.show(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: goals.length.clamp(0, _goalPreview),
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => GoalCard(
                      goal: goals[i],
                      onTap: () =>
                          EditGoalSheet.show(context, existing: goals[i]),
                      onMenu: () => _showGoalMenu(context, ref, goals[i]),
                    ),
                  ),
                ),

              // ---- Budgets
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                  child: SectionHeader(
                    title: 'Budgets',
                    trailingLabel: 'View All',
                    onTrailingTap: () => BudgetsScreen.open(context),
                  ),
                ),
              ),
              if (budgets.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyBlock(
                    icon: Icons.pie_chart_rounded,
                    title: 'No budgets yet',
                    body:
                        'Cap a category each month and get a warning before you overspend.',
                    actionLabel: 'Add a budget',
                    onAction: () => EditBudgetSheet.show(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: budgets.length.clamp(0, _budgetPreview),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => BudgetRow(
                      status: budgets[i],
                      onTap: () => EditBudgetSheet.show(
                        context,
                        existing: budgets[i].budget,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: kNavBarScrollPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 10,
          bottom: 16 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: AppColors.brand),
              title: const Text(
                'New goal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Save towards something specific'),
              onTap: () {
                Navigator.of(ctx).pop();
                EditGoalSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.pie_chart_rounded,
                color: AppColors.catBlue,
              ),
              title: const Text(
                'New budget',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Cap your spending for a month'),
              onTap: () {
                Navigator.of(ctx).pop();
                EditBudgetSheet.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalMenu(BuildContext context, WidgetRef ref, Goal goal) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 10,
          bottom: 16 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.add_circle_outline_rounded, color: p.income),
              title: const Text(
                'Add money',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _contribute(context, ref, goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.brand),
              title: const Text(
                'Edit goal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                EditGoalSheet.show(context, existing: goal);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: p.expense),
              title: Text(
                'Delete goal',
                style: TextStyle(fontWeight: FontWeight.w600, color: p.expense),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(actionsProvider).deleteGoal(goal.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final entered = await TextPromptDialog.show(
      context,
      title: 'Add to ${goal.name}',
      hintText: '0',
      prefixText: '$kCurrencySymbol ',
      keyboardType: TextInputType.number,
      confirmLabel: 'Add',
    );
    final amount = Money.parse(entered ?? '');
    if (amount != null && amount > 0) {
      await ref.read(actionsProvider).contributeToGoal(goal.id, amount);
    }
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: p.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: p.inkFaint),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: p.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
