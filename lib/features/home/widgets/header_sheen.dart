import 'dart:ui';

import 'package:flutter/material.dart';

/// The soft glassy streaks across the purple header: two rotated white shapes,
/// heavily blurred and barely opaque. Painted behind the header's content and
/// clipped to it, so nothing bleeds onto the sheet below.
class HeaderSheen extends StatelessWidget {
  const HeaderSheen({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -70,
              top: -40,
              child: _Streak(
                width: 420,
                height: 150,
                angle: -0.42,
                opacity: 0.12,
              ),
            ),
            Positioned(
              right: -120,
              bottom: -70,
              child: _Streak(
                width: 360,
                height: 190,
                angle: -0.52,
                opacity: 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak({
    required this.width,
    required this.height,
    required this.angle,
    required this.opacity,
  });

  final double width;
  final double height;
  final double angle;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
