import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// The filled/empty dots above a PIN keypad.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.color = AppColors.brand,
    this.error = false,
  });

  final int length;
  final int filled;
  final Color color;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final tone = error ? AppColors.expense : color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? tone : Colors.transparent,
              border: Border.all(
                color: i < filled ? tone : tone.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

/// PIN keypad: ten digits, an optional biometric key, and backspace.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['bio', '0', 'del'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                _Key(
                  label: key,
                  enabled: key != 'bio' || onBiometric != null,
                  onTap: switch (key) {
                    'bio' => onBiometric ?? () {},
                    'del' => onBackspace,
                    _ => () => onDigit(key),
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, required this.enabled});

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (label) {
      case 'del':
        content = const Icon(
          Icons.backspace_outlined,
          size: 22,
          color: AppColors.ink,
        );
      case 'bio':
        content = enabled
            ? const Icon(
                Icons.fingerprint_rounded,
                size: 28,
                color: AppColors.brand,
              )
            : const SizedBox.shrink();
      default:
        content = Text(
          label,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 76,
        height: 66,
        child: enabled
            ? Material(
                color: label == 'del' || label == 'bio'
                    ? Colors.transparent
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
                  child: Center(child: content),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
