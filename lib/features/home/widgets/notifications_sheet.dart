import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/glyph_tile.dart';
import '../../../core/widgets/progress.dart';
import '../../../data/repository/finance_repository.dart';
import '../../../providers/providers.dart';

/// Budget alerts, reached from the bell in the header. This is where the
/// "budgets + alerts" feature surfaces: anything at or over its threshold.
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NotificationsSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts =
        ref.watch(budgetAlertsProvider).value ?? const <BudgetStatus>[];
    final enabled = ref.watch(settingsProvider.select((s) => s.budgetAlerts));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  enabled ? '${alerts.length} active' : 'Muted',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          if (!enabled)
            const _Placeholder(
              icon: Icons.notifications_off_rounded,
              title: 'Alerts are switched off',
              body:
                  'Turn budget alerts back on in Settings to see warnings here.',
            )
          else if (alerts.isEmpty)
            const _Placeholder(
              icon: Icons.verified_rounded,
              title: 'Every budget is on track',
              body:
                  'You will see a warning here as soon as one gets close to its limit.',
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _AlertRow(status: alerts[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final over = status.isOver;
    final tone = over ? AppColors.expense : AppColors.warning;
    final pct = (status.rawProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint(tone),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlyphTile(icon: status.budget.icon, color: tone, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.budget.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  over
                      ? 'Over by ${Money.format(status.spent - status.budget.limit, decimals: false)} — $pct% of the limit used.'
                      : '$pct% used. ${Money.format(status.remaining, decimals: false)} left this month.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                ProgressTrack(
                  value: status.progress,
                  color: tone,
                  height: 6,
                  trackColor: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 26, 32, 40),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.inkFaint),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
