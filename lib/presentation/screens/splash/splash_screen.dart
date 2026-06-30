import 'package:flutter/material.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 116,
          height: 116,
          child: CustomPaint(painter: _DietBuddyIconPainter()),
        ),
      ),
    );
  }
}

class _DietBuddyIconPainter extends CustomPainter {
  const _DietBuddyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.235),
    );

    final tilePaint = Paint()
      ..isAntiAlias = true
      ..color = AppColors.textPrimary;
    canvas.drawRRect(tile, tilePaint);

    final glyphPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.092
      ..color = AppColors.background;

    final plate = Path()
      ..moveTo(size.width * 0.28, size.height * 0.55)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.72,
        size.width * 0.64,
        size.height * 0.72,
        size.width * 0.72,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.45,
        size.width * 0.34,
        size.height * 0.45,
        size.width * 0.28,
        size.height * 0.55,
      );
    canvas.drawPath(plate, glyphPaint);

    final appetitePaint = Paint()
      ..isAntiAlias = true
      ..color = AppColors.calories;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.34),
      size.width * 0.052,
      appetitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
