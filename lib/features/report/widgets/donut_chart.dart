import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_palette.dart';

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
    this.hatched = false,
  });

  final String label;
  final double value;
  final Color color;

  /// Drawn as diagonal stripes instead of a solid fill — used for the
  /// grouped "Other" remainder.
  final bool hatched;
}

/// The ring from the Report comp: thick rounded-cap arcs with a gap between
/// them, a total in the hole, and a tooltip on the selected slice.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
    this.stroke = 44,
    this.gapDegrees = 4,
  });

  final List<DonutSlice> slices;
  final String centerLabel;
  final Widget centerValue;
  final double stroke;
  final double gapDegrees;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  int? _selected;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  late final Animation<double> _sweep = CurvedAnimation(
    parent: _grow,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    if (old.slices.length != widget.slices.length) {
      _selected = null;
      _grow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  void _handleTap(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final v = local - center;
    final radius = v.distance;
    final outer = math.min(size.width, size.height) / 2;
    final inner = outer - widget.stroke;
    if (radius < inner - 10 || radius > outer + 10) {
      setState(() => _selected = null);
      return;
    }

    // Angle measured clockwise from twelve o'clock.
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;

    final total = widget.slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    var cursor = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final sweep = widget.slices[i].value / total * math.pi * 2;
      if (angle >= cursor && angle < cursor + sweep) {
        setState(() => _selected = _selected == i ? null : i);
        return;
      }
      cursor += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = widget.slices.fold<double>(0, (s, e) => s + e.value);

    return LayoutBuilder(
      builder: (context, c) {
        final size = Size.square(math.min(c.maxWidth, 300));
        return Center(
          child: GestureDetector(
            onTapUp: (d) => _handleTap(d.localPosition, size),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) => CustomPaint(
                  painter: _DonutPainter(
                    emptyColor: context.palette.track,
                    slices: widget.slices,
                    stroke: widget.stroke,
                    gapDegrees: widget.gapDegrees,
                    progress: _sweep.value,
                    selected: _selected,
                  ),
                  foregroundPainter: _selected == null || total <= 0
                      ? null
                      : _TooltipPainter(
                          slices: widget.slices,
                          stroke: widget.stroke,
                          selected: _selected!,
                          text:
                              '${(widget.slices[_selected!].value / total * 100).round()}%',
                          textDirection: Directionality.of(context),
                        ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selected == null
                              ? widget.centerLabel
                              : widget.slices[_selected!].label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: p.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        widget.centerValue,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.emptyColor,
    required this.slices,
    required this.stroke,
    required this.gapDegrees,
    required this.progress,
    required this.selected,
  });

  /// Painted when there is nothing to chart; a painter has no context.
  final Color emptyColor;
  final List<DonutSlice> slices;
  final double stroke;
  final double gapDegrees;
  final double progress;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final outer = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: outer - stroke / 2,
    );

    if (total <= 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = emptyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      return;
    }

    final gap = gapDegrees * math.pi / 180;
    var start = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final full = slice.value / total * math.pi * 2;
      final sweep = (full - gap) * progress;
      if (sweep <= 0) {
        start += full;
        continue;
      }

      final isDimmed = selected != null && selected != i;
      final color = isDimmed
          ? Color.alphaBlend(slice.color.withValues(alpha: 0.28), Colors.white)
          : slice.color;

      final arcRect = selected == i ? rect.inflate(3) : rect;

      if (slice.hatched) {
        _paintHatched(canvas, arcRect, start + gap / 2, sweep, color);
      } else {
        canvas.drawArc(
          arcRect,
          start + gap / 2,
          sweep,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = selected == i ? stroke + 4 : stroke,
        );
      }
      start += full;
    }
  }

  /// Diagonal stripes confined to the arc band.
  void _paintHatched(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Color color,
  ) {
    // A base wash so the band still reads between the stripes.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );

    // `rect` is the mid-line of the band, so the sector runs from mid-stroke/2
    // to mid+stroke/2.
    final center = rect.center;
    final mid = rect.width / 2;
    final band = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: mid + stroke / 2),
        start,
        sweep,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: mid - stroke / 2),
        start + sweep,
        -sweep,
        false,
      )
      ..close();

    canvas.save();
    canvas.clipPath(band);
    final stripe = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final b = band.getBounds();
    for (var x = b.left - b.height; x < b.right + b.height; x += 9) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.slices != slices;
}

/// The little black "31%" badge pinned to the selected slice.
class _TooltipPainter extends CustomPainter {
  _TooltipPainter({
    required this.slices,
    required this.stroke,
    required this.selected,
    required this.text,
    required this.textDirection,
  });

  final List<DonutSlice> slices;
  final double stroke;
  final int selected;
  final String text;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < selected; i++) {
      start += slices[i].value / total * math.pi * 2;
    }
    final mid = start + (slices[selected].value / total * math.pi * 2) / 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final anchor = center + Offset(math.cos(mid), math.sin(mid)) * radius;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final w = painter.width + 20;
    const h = 28.0;
    final box = Rect.fromCenter(center: anchor, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(14)),
      Paint()..color = const Color(0xFF17171F),
    );
    painter.paint(
      canvas,
      Offset(
        box.center.dx - painter.width / 2,
        box.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_TooltipPainter old) =>
      old.selected != selected || old.text != text;
}
