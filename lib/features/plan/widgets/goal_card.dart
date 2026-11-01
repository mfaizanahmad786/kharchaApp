import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glyph_tile.dart';
import '../../../core/widgets/progress.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_palette.dart';

/// The featured goal card: saved-of-target, a bar whose hatched band is the
/// shortfall against schedule, and a warning strip when you are behind.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onTap, this.onMenu});

  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final behind = goal.isBehind;
    final gapPercent = (goal.scheduleGap * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: p.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GlyphTile(
                          icon: goal.icon,
                          color: goal.color,
                          size: 48,
                          radius: 16,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.deadline == null
                                    ? 'No deadline'
                                    : 'by ${AppDate.shortDay(goal.deadline!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: p.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onMenu,
                          icon: const Icon(Icons.more_vert_rounded),
                          color: p.inkFaint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AmountText(
                              goal.saved,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                              ),
                              fractionOpacity: 0.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Out of',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: p.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 5),
                        AmountText(
                          goal.target,
                          color: p.inkFaint,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          fractionOpacity: 0.7,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    HatchedGoalBar(
                      progress: goal.progress,
                      expected: goal.expectedProgress,
                      color: goal.color,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Your Progress',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: p.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        AmountText(
                          goal.remaining,
                          showDecimals: false,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          ' Left',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (behind)
                Container(
                  width: double.infinity,
                  color: AppColors.warning,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          "You're $gapPercent% behind schedule and off target.",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (goal.progress >= 1)
                Container(
                  width: double.infinity,
                  color: p.income,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Goal reached. Nicely done.',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
