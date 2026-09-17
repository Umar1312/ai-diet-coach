import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class NextMealAppIcon extends StatelessWidget {
  final double size;
  final double animationProgress;

  const NextMealAppIcon({
    super.key,
    required this.size,
    this.animationProgress = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'NextMeal',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MacroMarkPainter(animationProgress),
          child: Center(
            child: _AnimatedFlatware(
              size: size * .31,
              progress: animationProgress,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroMarkPainter extends CustomPainter {
  final double progress;
  _MacroMarkPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawRing(
      canvas,
      center: center,
      radius: size.width * .405,
      strokeWidth: size.width * .064,
      trackColor: AppColors.caloriesLight,
      activeColor: AppColors.calories,
      activeSweep:
          math.pi *
          1.5 *
          Curves.easeInOutCubic.transform((progress / .75).clamp(0, 1)),
    );
    _drawRing(
      canvas,
      center: center,
      radius: size.width * .305,
      strokeWidth: size.width * .055,
      trackColor: AppColors.proteinLight,
      activeColor: AppColors.protein,
      activeSweep:
          math.pi *
          1.27 *
          Curves.easeInOutCubic.transform(((progress - .12) / .78).clamp(0, 1)),
    );
  }

  void _drawRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double strokeWidth,
    required Color trackColor,
    required Color activeColor,
    required double activeSweep,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (activeSweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, activeSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MacroMarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedFlatware extends StatelessWidget {
  const _AnimatedFlatware({required this.size, required this.progress});
  final double size, progress;

  double get angle {
    if (progress >= 1) return 0;
    if (progress < .3) {
      return -.18 * Curves.easeInOut.transform((progress / .3).clamp(0, 1));
    }
    if (progress < .48) {
      return -.18 + .52 * Curves.easeInCubic.transform((progress - .3) / .18);
    }
    final elapsed = (progress - .48) / .52;
    // Collision impulse followed by a damped rotational spring.
    return .34 *
        math.exp(-6 * elapsed) *
        math.cos(17 * elapsed) *
        (1 - elapsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final left in [true, false])
            Transform.rotate(
              angle: left ? angle : -angle,
              alignment: left
                  ? const Alignment(-.4, .75)
                  : const Alignment(.4, .75),
              child: CustomPaint(
                size: Size.square(size),
                painter: _LogoUtensilPainter(isFork: left),
              ),
            ),
        ],
      ),
    );
  }
}

/// Silhouettes matched to the fork and spoon in nextmeal-app-icon.png.
/// Each utensil owns its full shape so rotation cannot expose another glyph.
class _LogoUtensilPainter extends CustomPainter {
  const _LogoUtensilPainter({required this.isFork});
  final bool isFork;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final path = isFork ? _forkPath() : _spoonPath();
    canvas.drawPath(path, Paint()..color = AppColors.textPrimary);
    canvas.restore();
  }

  // The reference mark has three rounded tines and a gently tapered handle.
  Path _forkPath() => Path()
    ..moveTo(11, 5)
    ..cubicTo(11, 0, 19, 0, 19, 5)
    ..lineTo(19, 24)
    ..cubicTo(19, 28, 23, 28, 23, 24)
    ..lineTo(23, 5)
    ..cubicTo(23, 0, 31, 0, 31, 5)
    ..lineTo(31, 24)
    ..cubicTo(31, 28, 35, 28, 35, 24)
    ..lineTo(35, 5)
    ..cubicTo(35, 0, 43, 0, 43, 5)
    ..lineTo(43, 27)
    ..cubicTo(43, 34, 39, 39, 35, 42)
    ..cubicTo(33, 43, 33, 45, 33, 48)
    ..lineTo(35, 90)
    ..cubicTo(36, 103, 18, 103, 19, 90)
    ..lineTo(21, 48)
    ..cubicTo(21, 45, 21, 43, 19, 42)
    ..cubicTo(15, 39, 11, 34, 11, 27)
    ..close();

  Path _spoonPath() => Path()
    ..moveTo(72, 1)
    ..cubicTo(82, 1, 89, 12, 89, 23)
    ..cubicTo(89, 32, 85, 38, 81, 41)
    ..cubicTo(78, 43, 78, 45, 78, 48)
    ..lineTo(80, 90)
    ..cubicTo(81, 103, 63, 103, 64, 90)
    ..lineTo(66, 48)
    ..cubicTo(66, 45, 66, 43, 63, 41)
    ..cubicTo(59, 38, 55, 32, 55, 23)
    ..cubicTo(55, 12, 62, 1, 72, 1)
    ..close();

  @override
  bool shouldRepaint(covariant _LogoUtensilPainter oldDelegate) =>
      isFork != oldDelegate.isFork;
}
