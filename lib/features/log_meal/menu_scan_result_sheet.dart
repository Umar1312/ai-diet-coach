import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/shared/models/recommended_dish.dart';
import 'package:diet_coach_ai/presentation/widgets/primary_button.dart';

class MenuScanResultSheet extends StatelessWidget {
  final MenuScanResponse scanResponse;

  const MenuScanResultSheet({super.key, required this.scanResponse});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.calories.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.calories,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Recommendations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            scanResponse.restaurantContext,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: scanResponse.recommendations.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, index) {
                final dish = scanResponse.recommendations[index];
                return _DishRecommendationCard(
                  dish: dish,
                  onLog: () {
                    HapticFeedback.mediumImpact();
                    context.go('/home');
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                scanResponse.recommendations.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == 0 ? AppColors.primary : AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DishRecommendationCard extends StatelessWidget {
  final RecommendedDish dish;
  final VoidCallback onLog;

  const _DishRecommendationCard({required this.dish, required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.calories.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dish.dishName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.calories.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.calories.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${dish.estimatedCalories}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.calories,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                _MicroStat(
                  label: 'P',
                  value: '${dish.estimatedProtein}g',
                  color: AppColors.protein,
                ),
                const SizedBox(width: 12),
                _MicroStat(
                  label: 'C',
                  value: '${dish.estimatedCarbs}g',
                  color: AppColors.carbs,
                ),
                const SizedBox(width: 12),
                _MicroStat(
                  label: 'F',
                  value: '${dish.estimatedFats}g',
                  color: AppColors.fats,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dish.whyItFits,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (dish.modifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    size: 14,
                    color: AppColors.aiGlow,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dish.modifications,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          PrimaryButton(text: 'Log This Choice', onPressed: onLog),
        ],
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MicroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
