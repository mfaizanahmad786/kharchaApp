import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/month_picker_sheet.dart';
import '../../data/models/models.dart';
import '../../data/repository/finance_repository.dart';
import '../../providers/providers.dart';
import 'edit_budget_sheet.dart';
import 'edit_goal_sheet.dart';
import 'widgets/budget_row.dart';
import 'widgets/goal_card.dart';
import '../../core/theme/app_fonts.dart';

/// "View All" for goals.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: _bar(context, 'Goals', () => EditGoalSheet.show(context)),
      body: goals.isEmpty
          ? const _Empty(text: 'No goals yet. Tap + to add one.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => GoalCard(
                goal: goals[i],
                onTap: () => EditGoalSheet.show(context, existing: goals[i]),
                onMenu: () => EditGoalSheet.show(context, existing: goals[i]),
              ),
            ),
    );
  }
}

/// "View All" for budgets.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const BudgetsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets =
        ref.watch(budgetStatusesProvider).value ?? const <BudgetStatus>[];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: _bar(
        context,
        'Budgets',
        () => EditBudgetSheet.show(context),
        showMonth: true,
      ),
      body: budgets.isEmpty
          ? const _Empty(text: 'No budgets yet. Tap + to add one.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => BudgetRow(
                status: budgets[i],
                onTap: () =>
                    EditBudgetSheet.show(context, existing: budgets[i].budget),
              ),
            ),
    );
  }
}

AppBar _bar(
  BuildContext context,
  String title,
  VoidCallback onAdd, {
  bool showMonth = false,
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(title),
    titleTextStyle: const TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    actions: [
      if (showMonth) const MonthPill(onLight: true),
      IconButton(
        icon: const Icon(Icons.add_rounded, color: AppColors.ink),
        onPressed: onAdd,
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
