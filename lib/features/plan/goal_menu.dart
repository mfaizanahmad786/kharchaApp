import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'edit_goal_sheet.dart';

/// The goal's own actions, shared by the Plan screen and the goals list so
/// pinning is reachable wherever a goal is.
void showGoalMenu(BuildContext context, WidgetRef ref, Goal goal) {
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
            leading: Icon(
              goal.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: AppColors.brand,
            ),
            title: Text(
              goal.pinned ? 'Unpin from Plan' : 'Pin to Plan',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              goal.pinned
                  ? 'Stop featuring this goal at the top'
                  : 'Feature this goal at the top of Plan',
            ),
            onTap: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(actionsProvider)
                  .setPinnedGoal(goal.id, pinned: !goal.pinned);
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

Future<void> _contribute(BuildContext context, WidgetRef ref, Goal goal) async {
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
