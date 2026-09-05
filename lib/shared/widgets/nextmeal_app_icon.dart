import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class NextMealAppIcon extends StatelessWidget {
  final double size;

  const NextMealAppIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'NextMeal',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MacroMarkPainter(),
          child: Center(
            child: Icon(
              Icons.flatware_rounded,
              size: size * .31,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroMarkPainter extends CustomPainter {
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
      activeSweep: math.pi * 1.5,
    );
    _drawRing(
      canvas,
      center: center,
      radius: size.width * .305,
      strokeWidth: size.width * .055,
      trackColor: AppColors.proteinLight,
      activeColor: AppColors.protein,
      activeSweep: math.pi * 1.27,
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
    canvas.drawArc(rect, -math.pi / 2, activeSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _MacroMarkPainter oldDelegate) => false;
}
