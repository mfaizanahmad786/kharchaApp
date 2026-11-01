import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme/app_colors.dart';
import '../utils/app_date.dart';
import '../theme/app_palette.dart';

/// The month selector behind the "November 2025 ⌄" pill.
class MonthPickerSheet extends ConsumerStatefulWidget {
  const MonthPickerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MonthPickerSheet(),
  );

  @override
  ConsumerState<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends ConsumerState<MonthPickerSheet> {
  late int _year = ref.read(selectedMonthProvider).year;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = ref.watch(selectedMonthProvider);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.viewPaddingOf(context).bottom,
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
          const SizedBox(height: 18),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left_rounded),
                color: p.ink,
              ),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _year >= now.year
                    ? null
                    : () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right_rounded),
                color: p.ink,
                disabledColor: p.inkFaint.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (context, i) {
              final month = DateTime(_year, i + 1);
              final isSelected =
                  selected.year == _year && selected.month == i + 1;
              final isFuture = month.isAfter(AppDate.startOfMonth(now));
              return Material(
                color: isSelected ? AppColors.brand : p.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isFuture
                      ? null
                      : () {
                          ref.read(selectedMonthProvider.notifier).set(month);
                          Navigator.of(context).pop();
                        },
                  child: Center(
                    child: Text(
                      _months[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isFuture
                            ? p.inkFaint.withValues(alpha: 0.4)
                            : p.ink,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The "November 2025 ⌄" pill itself.
class MonthPill extends ConsumerWidget {
  const MonthPill({super.key, this.onLight = false});

  /// True when the pill sits on a light surface rather than the purple header.
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final month = ref.watch(selectedMonthProvider);
    final fg = onLight ? p.ink : Colors.white;
    return Material(
      color: onLight ? p.surface : Colors.white.withValues(alpha: 0.18),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => MonthPickerSheet.show(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: onLight ? p.softShadow : null,
            color: onLight ? p.surface : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppDate.monthYear(month),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
