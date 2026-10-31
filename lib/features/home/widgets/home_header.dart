import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/month_picker_sheet.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/utils/money.dart';
import '../../../providers/providers.dart';

/// The violet balance header: avatar, month pill, bell, and the big number.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.onAvatarTap,
    required this.onBellTap,
  });

  final VoidCallback onAvatarTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final balance = ref.watch(balanceProvider);
    final delta = ref.watch(weekDeltaProvider);
    final alerts = ref.watch(budgetAlertsProvider);
    final name = ref.watch(settingsProvider.select((s) => s.userName));

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: topInset + 12,
            left: 20,
            right: 20,
            bottom: 46,
          ),
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Column(
            children: [
              Row(
                children: [
                  _Avatar(name: name, onTap: onAvatarTap),
                  const Spacer(),
                  const MonthPill(),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.notifications_rounded,
                    size: 44,
                    iconSize: 21,
                    background: Colors.white.withValues(alpha: 0.22),
                    foreground: Colors.white,
                    shadows: const [],
                    badge: alerts.value?.isNotEmpty ?? false,
                    onTap: onBellTap,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Current Balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              AmountText(
                balance.value ?? 0,
                color: Colors.white,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.6,
                  height: 1.1,
                ),
                fractionOpacity: 0.55,
              ),
              const SizedBox(height: 14),
              _DeltaPill(delta: delta.value ?? 0),
            ],
          ),
        ),

        // The light sheet's rounded corners sit over the purple. They live
        // here because a viewport paints its first sliver on top, so the
        // following sliver could never overlap the header.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final sign = delta >= 0 ? '+' : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$sign${Money.compact(delta.abs())} than last week',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'K'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFCD9A8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A5A24),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 12,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
