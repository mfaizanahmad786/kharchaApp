import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// The two-tone amount used all over the comps: the rupees at full weight and
/// the paisa dimmed. Honours the global "hide amounts" preference.
class AmountText extends ConsumerWidget {
  const AmountText(
    this.paisa, {
    super.key,
    this.style,
    this.fractionStyle,
    this.color,
    this.showSign = false,
    this.showDecimals = true,
    this.showSymbol = true,
    this.fractionOpacity = 0.55,
    this.maskable = true,
  });

  final int paisa;
  final TextStyle? style;
  final TextStyle? fractionStyle;
  final Color? color;
  final bool showSign;
  final bool showDecimals;
  final bool showSymbol;
  final double fractionOpacity;

  /// Set false for places where masking would make the screen nonsensical.
  final bool maskable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden =
        maskable && ref.watch(settingsProvider.select((s) => s.hideAmounts));
    final base = (style ?? Theme.of(context).textTheme.titleMedium!)
        .copyWith(color: color ?? AppColors.ink);

    if (hidden) {
      return Text('${showSymbol ? kCurrencySymbol : ''}••••', style: base);
    }

    final sign = showSign
        ? (paisa < 0 ? '-' : '+')
        : (paisa < 0 ? '-' : '');
    final head = '$sign${showSymbol ? kCurrencySymbol : ''}${Money.whole(paisa)}';
    final tail = showDecimals ? '.${Money.fraction(paisa)}' : '';

    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: head),
          if (tail.isNotEmpty)
            TextSpan(
              text: tail,
              style: fractionStyle ??
                  base.copyWith(
                    color: (base.color ?? AppColors.ink)
                        .withValues(alpha: fractionOpacity),
                  ),
            ),
        ],
      ),
    );
  }
}
