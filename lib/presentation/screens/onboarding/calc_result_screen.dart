import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/macro_model.dart';
import '../../../stores/onboarding_store.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class CalcResultScreen extends StatefulWidget {
  const CalcResultScreen({super.key});

  @override
  State<CalcResultScreen> createState() => _CalcResultScreenState();
}

class _CalcResultScreenState extends State<CalcResultScreen> {
  final _store = OnboardingStore();
  MacroModel? _macros;

  @override
  void initState() {
    super.initState();

    _macros = MacroModel.calculateFromUser(
      weight: _store.weight ?? 70,
      height: _store.height ?? 175,
      age: _store.age?.toInt() ?? 25,
      gender: _store.gender ?? 'Male',
      activityLevel: _store.activityLevel ?? 'Sedentary',
      goal: _store.goal ?? 'Lose Weight',
    );
  }

  @override
  Widget build(BuildContext context) {
    final macros =
        _macros ??
        MacroModel(calories: 2000, carbs: 175, protein: 200, fats: 56);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const OnboardingProgressBar(step: 9, totalSteps: 9),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your plan\nis ready!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_store.targetWeight?.toInt() ?? 70} kg target',
                    style: const TextStyle(
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
                _MacroRow(
                  label: 'Calories',
                  value: '${macros.calories.toInt()}',
                  unit: 'kcal',
                  color: AppColors.calories,
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Protein',
                  value: '${macros.protein.toInt()}',
                  unit: 'g',
                  color: AppColors.protein,
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Carbs',
                  value: '${macros.carbs.toInt()}',
                  unit: 'g',
                  color: AppColors.carbs,
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Fats',
                  value: '${macros.fats.toInt()}',
                  unit: 'g',
                  color: AppColors.fats,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: "Let's get started!",
                  onPressed: () => context.push('/onboarding/notifications'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
