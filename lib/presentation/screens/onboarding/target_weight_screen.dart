import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../stores/onboarding_store.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class TargetWeightScreen extends StatefulWidget {
  const TargetWeightScreen({super.key});

  @override
  State<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends State<TargetWeightScreen> {
  final _store = OnboardingStore();
  bool _isKg = true;
  double _targetKg = 65;
  double _targetLbs = 143;

  double get _targetInKg => _isKg ? _targetKg : _targetLbs / 2.205;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const OnboardingProgressBar(step: 7, totalSteps: 8),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'What\'s your\ntarget weight?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _UnitToggle(
                        label: 'kg',
                        isSelected: _isKg,
                        onTap: () => setState(() => _isKg = true),
                      ),
                      _UnitToggle(
                        label: 'lbs',
                        isSelected: !_isKg,
                        onTap: () => setState(() => _isKg = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(child: _isKg ? _buildKgPicker() : _buildLbsPicker()),
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  _store.updateUser(targetWeight: _targetInKg);
                  context.push('/onboarding/restrictions');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKgPicker() {
    return Column(
      children: [
        Text(
          _targetKg.round().toString(),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'kg',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 40),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surface,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _targetKg,
            min: 30,
            max: 200,
            onChanged: (value) => setState(() => _targetKg = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              Text(
                '200',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLbsPicker() {
    return Column(
      children: [
        Text(
          _targetLbs.round().toString(),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'lbs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 40),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surface,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _targetLbs,
            min: 66,
            max: 440,
            onChanged: (value) => setState(() => _targetLbs = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '66',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              Text(
                '440',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
