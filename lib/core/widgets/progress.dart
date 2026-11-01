import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Flat rounded progress bar.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
    this.trackColor,
  });

  final double value;
  final Color color;
  final double height;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: trackColor ?? AppColors.tint(color),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    );
  }
}

/// The goal bar from the Plan comp: a solid fill for what has actually been
/// saved, a hatched band covering the shortfall against where the plan says
/// you should be by now, and a knob at the real position.
class HatchedGoalBar extends StatelessWidget {
  const HatchedGoalBar({
    super.key,
    required this.progress,
    required this.expected,
    required this.color,
    this.height = 14,
  });

  final double progress;
  final double expected;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 8,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _HatchedGoalPainter(
            progress: v,
            expected: expected.clamp(0.0, 1.0),
            color: color,
            barHeight: height,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _HatchedGoalPainter extends CustomPainter {
  _HatchedGoalPainter({
    required this.progress,
    required this.expected,
    required this.color,
    required this.barHeight,
  });

  final double progress;
  final double expected;
  final Color color;
  final double barHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - barHeight) / 2;
    final rect = Rect.fromLTWH(0, top, size.width, barHeight);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(barHeight / 2));

    // Track
    canvas.drawRRect(rrect, Paint()..color = AppColors.tint(color));

    canvas.save();
    canvas.clipRRect(rrect);

    // Hatched band: from actual progress up to where we should be.
    if (expected > progress) {
      final bandLeft = size.width * progress;
      final bandRight = size.width * expected;
      final band = Rect.fromLTRB(bandLeft, top, bandRight, top + barHeight);
      canvas.save();
      canvas.clipRect(band);
      final stroke = Paint()
        ..color = color.withValues(alpha: 0.38)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      const step = 7.0;
      for (var x = bandLeft - barHeight; x < bandRight + barHeight; x += step) {
        canvas.drawLine(
          Offset(x, top + barHeight),
          Offset(x + barHeight, top),
          stroke,
        );
      }
      canvas.restore();
    }

    // Solid fill for actual progress.
    if (progress > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width * progress, barHeight),
        Paint()..color = color,
      );
    }
    canvas.restore();

    // Knob
    final knobX = (size.width * progress).clamp(
      barHeight / 2,
      size.width - barHeight / 2,
    );
    final knobCenter = Offset(knobX, size.height / 2);
    canvas.drawCircle(
      knobCenter,
      barHeight * 0.72,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      knobCenter,
      barHeight * 0.72,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_HatchedGoalPainter old) =>
      old.progress != progress ||
      old.expected != expected ||
      old.color != color;
}

/// Circular percentage ring with the value in the middle — the budget rows.
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    required this.color,
    this.size = 54,
    this.stroke = 4.5,
    this.label,
    this.labelStyle,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final String? label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final text = label ?? '${(value * 100).round()}%';
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(value: v, color: color, stroke: stroke),
          child: Center(
            child: Text(
              text,
              style:
                  labelStyle ??
                  TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
  });

  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2 + 1);
    canvas.drawArc(
      inset,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.tint(color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    canvas.drawArc(
      inset,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}
