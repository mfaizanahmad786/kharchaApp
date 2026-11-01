import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../../core/theme/app_palette.dart';

/// Daily totals for the selected month. Tapping a bar reveals its value.
class SpendBarChart extends StatefulWidget {
  const SpendBarChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 240,
  });

  final List<({DateTime day, int total})> data;
  final Color color;
  final double height;

  @override
  State<SpendBarChart> createState() => _SpendBarChartState();
}

class _SpendBarChartState extends State<SpendBarChart>
    with SingleTickerProviderStateMixin {
  int? _selected;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No activity this month.',
            style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final max = widget.data.fold<int>(0, (m, e) => math.max(m, e.total));
    final selected = _selected == null ? null : widget.data[_selected!];

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: Center(
            child: AnimatedOpacity(
              opacity: selected == null ? 0 : 1,
              duration: const Duration(milliseconds: 160),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  selected == null
                      ? ''
                      : '${selected.day.day}/${selected.day.month} · ${Money.format(selected.total, decimals: false)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, c) {
              final slot = c.maxWidth / widget.data.length;
              final barWidth = math.max(3.0, math.min(slot - 3, 14.0));
              return AnimatedBuilder(
                animation: _grow,
                builder: (context, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < widget.data.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(
                            () => _selected = _selected == i ? null : i,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: barWidth,
                                height: max == 0
                                    ? 3
                                    : math.max(
                                        3,
                                        (widget.data[i].total / max) *
                                            (widget.height - 26) *
                                            Curves.easeOutCubic.transform(
                                              _grow.value,
                                            ),
                                      ),
                                decoration: BoxDecoration(
                                  color: _selected == null || _selected == i
                                      ? widget.color
                                      : widget.color.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(barWidth),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 14,
                                // A day slot is only a few pixels wide, so the
                                // two-digit labels have to paint past it.
                                child: _shouldLabel(i)
                                    ? OverflowBox(
                                        maxWidth: 32,
                                        child: Text(
                                          '${widget.data[i].day.day}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: p.inkFaint,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Label roughly every fifth day so the axis stays readable.
  bool _shouldLabel(int i) {
    final day = widget.data[i].day.day;
    return day == 1 || day % 5 == 0;
  }
}
