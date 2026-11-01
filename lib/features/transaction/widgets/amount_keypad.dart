import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';

/// Numeric pad for amount entry. Keeping the OS keyboard out of the way means
/// the category picker and the running total stay visible while you type.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['.', '0', '<'],
        ])
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(
                    label: key,
                    onTap: switch (key) {
                      '.' => onDecimal,
                      '<' => onBackspace,
                      _ => () => onDigit(key),
                    },
                    onLongPress: key == '<' ? onClear : null,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.onLongPress});

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isBackspace = label == '<';
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          child: SizedBox(
            height: 50,
            child: Center(
              child: isBackspace
                  ? Semantics(
                      label: 'Delete last digit',
                      button: true,
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 21,
                        color: p.ink,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
