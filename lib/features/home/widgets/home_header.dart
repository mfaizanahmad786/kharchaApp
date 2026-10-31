import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/month_picker_sheet.dart';
import '../../../providers/providers.dart';
import 'header_sheen.dart';

/// The violet balance header: avatar, month pill, bell, and the balance set
/// large with its paisa dimmed.
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
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: const HeaderSheen(),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: topInset + AppSpacing.md,
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            bottom: 46,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _Avatar(name: name, onTap: onAvatarTap),
                  const Spacer(),
                  const MonthPill(),
                  const Spacer(),
                  _BellButton(
                    hasAlerts: alerts.value?.isNotEmpty ?? false,
                    onTap: onBellTap,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Current Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  // Green carries more luminance than the old violet, so the
                  // label needs a touch more opacity to stay readable on it.
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AmountText(
                  balance.value ?? 0,
                  color: Colors.white,
                  style: const TextStyle(
                    // The brief said ~56, but measured against the reference
                    // the balance is ~2.7x the label above it, i.e. ~44-48.
                    // A PKR figure also carries more digits than the comp's
                    // dollar one, so 56 crowded both gutters.
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.6,
                    height: 1.12,
                  ),
                  fractionOpacity: 0.58,
                ),
              ),
              const SizedBox(height: 10),
              _DeltaPill(delta: delta.value ?? 0),
            ],
          ),
        ),

        // The sheet's rounded corners sit over the purple. They live here
        // because a viewport paints its first sliver on top, so the following
        // sliver could never overlap the header.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: AppRadii.sheet,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.sheetTop,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const StadiumBorder(),
      ),
      child: Text(
        '${delta >= 0 ? '+' : '-'}${Money.compact(delta.abs())} than last week',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A translucent circle with the bell, the alert dot pinned to its top-right.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasAlerts, required this.onTap});

  final bool hasAlerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = AppSizes.bellButton;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: const SizedBox(
                width: size,
                height: size,
                child: Icon(
                  Icons.notifications_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (hasAlerts)
            Positioned(
              right: 1,
              top: 3,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.expense,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
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
        width: AppSizes.avatar,
        height: AppSizes.avatar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: AppSizes.avatar / 2,
              backgroundColor: const Color(0xFFFCD9A8),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A5A24),
                ),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 11,
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
