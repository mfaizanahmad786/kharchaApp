import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/models.dart';
import '../../data/repository/finance_repository.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';
import '../shell/bottom_nav.dart';
import 'edit_budget_sheet.dart';
import 'edit_goal_sheet.dart';
import 'plan_list_screens.dart';
import 'widgets/budget_row.dart';
import 'widgets/goal_card.dart';

/// Goals (savings targets) on top, budgets (monthly spending ceilings) below.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static const _goalPreview = 1;
  static const _budgetPreview = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final budgets =
        ref.watch(budgetStatusesProvider).value ?? const <BudgetStatus>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
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
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.ink,
                        ),
                        onPressed: () => ShellNavigator.of(context)?.go(0),
                      ),
                      Text(
                        'My Plan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      CircleIconButton(
                        icon: Icons.add_rounded,
                        size: 44,
                        iconSize: 23,
                        background: const Color(0xFF17171F),
                        foreground: Colors.white,
                        onTap: () => _showAddMenu(context),
                      ),
                      const SizedBox(width: 10),
                      CircleIconButton(
                        icon: Icons.north_east_rounded,
                        size: 44,
                        iconSize: 19,
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
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
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
                color: AppColors.track,
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
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
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
                color: AppColors.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.income,
              ),
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
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
              ),
              title: const Text(
                'Delete goal',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.expense,
                ),
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
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '$kCurrencySymbol ',
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(Money.parse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
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
