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
    final icon = Icon(
      Icons.flatware_rounded,
      size: size,
      color: AppColors.textPrimary,
    );
    if (progress >= 1) return icon;
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
              child: ClipRect(clipper: _UtensilClipper(left), child: icon),
            ),
        ],
      ),
    );
  }
}

class _UtensilClipper extends CustomClipper<Rect> {
  const _UtensilClipper(this.left);
  final bool left;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(left ? 0 : size.width / 2, 0, size.width / 2, size.height);
  @override
  bool shouldReclip(_UtensilClipper oldClipper) => left != oldClipper.left;
}
