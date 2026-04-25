import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class MacroRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final double progress;
  final Color color;
  final String label;
  final String? sublabel;
  final Color? gradientEnd;

  const MacroRing({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.color,
    required this.label,
    this.sublabel,
    this.gradientEnd,
  });

  @override
  State<MacroRing> createState() => _MacroRingState();
}

class _MacroRingState extends State<MacroRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(MacroRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final currentProgress = widget.progress * _animation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GradientRingPainter(
                  progress: currentProgress.clamp(0.0, 1.0),
                  color: widget.color,
                  gradientEnd:
                      widget.gradientEnd ??
                      HSLColor.fromColor(widget.color)
                          .withLightness(
                            (HSLColor.fromColor(widget.color).lightness + 0.15)
                                .clamp(0.0, 1.0),
                          )
                          .toColor(),
                  strokeWidth: widget.strokeWidth,
                  glowProgress: _animation.value,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  if (widget.sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.sublabel!,
                      style: TextStyle(
                        fontSize: widget.size * 0.09,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color gradientEnd;
  final double strokeWidth;
  final double glowProgress;

  _GradientRingPainter({
    required this.progress,
    required this.color,
    required this.gradientEnd,
    required this.strokeWidth,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle glow behind the arc
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2 * glowProgress)
      ..strokeWidth = strokeWidth + 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Gradient progress arc
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [color, gradientEnd],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // End-cap dot for a polished look
    if (progress > 0.02) {
      final endAngle = startAngle + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, strokeWidth * 0.25, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      glowProgress != oldDelegate.glowProgress;
}
