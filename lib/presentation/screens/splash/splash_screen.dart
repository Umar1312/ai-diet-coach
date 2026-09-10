import 'package:flutter/material.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/shared/widgets/nextmeal_app_icon.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
          duration: Duration(milliseconds: reducedMotion ? 1 : 1800),
          onEnd: onComplete,
          builder: (_, progress, _) =>
              NextMealAppIcon(size: 116, animationProgress: progress),
        ),
      ),
    );
  }
}
