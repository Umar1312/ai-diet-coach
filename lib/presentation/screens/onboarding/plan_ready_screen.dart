import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/macro_model.dart';
import '../../widgets/macro_card.dart';
import '../../widgets/primary_button.dart';

class PlanReadyScreen extends StatelessWidget {
  const PlanReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final macros = MacroModel(
      calories: 2191,
      carbs: 240,
      protein: 170,
      fats: 60,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!\nyour custom plan is ready',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'You should maintain:',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '77 kg',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Daily recommendation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You can edit this anytime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    MacroCard(
                      title: 'Calories',
                      icon: Icons.local_fire_department,
                      current: macros.calories,
                      target: macros.calories,
                      color: AppColors.calories,
                    ),
                    MacroCard(
                      title: 'Carbs',
                      icon: Icons.grain,
                      current: macros.carbs,
                      target: macros.carbs,
                      color: AppColors.carbs,
                    ),
                    MacroCard(
                      title: 'Protein',
                      icon: Icons.fitness_center,
                      current: macros.protein,
                      target: macros.protein,
                      color: AppColors.protein,
                    ),
                    MacroCard(
                      title: 'Fats',
                      icon: Icons.water_drop,
                      current: macros.fats,
                      target: macros.fats,
                      color: AppColors.fats,
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                text: "Let's get started!",
                onPressed: () => context.push('/onboarding/notifications'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
