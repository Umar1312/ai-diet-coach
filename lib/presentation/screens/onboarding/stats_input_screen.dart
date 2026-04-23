import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../stores/onboarding_store.dart';
import '../../widgets/primary_button.dart';

class StatsInputScreen extends StatefulWidget {
  const StatsInputScreen({super.key});

  @override
  State<StatsInputScreen> createState() => _StatsInputScreenState();
}

class _StatsInputScreenState extends State<StatsInputScreen> {
  final _store = OnboardingStore();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _ageController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _selectedGender != null;
  }

  void _onContinue() {
    if (_isValid) {
      _store.updateUser(
        age: double.tryParse(_ageController.text),
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        gender: _selectedGender,
      );
      context.push('/onboarding/activity');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const ProgressBar(progress: 0.2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us calculate your personalized nutrition plan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Gender selection
              Text('Gender', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.male,
                      label: 'Male',
                      isSelected: _selectedGender == 'Male',
                      onTap: () => setState(() => _selectedGender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.female,
                      label: 'Female',
                      isSelected: _selectedGender == 'Female',
                      onTap: () => setState(() => _selectedGender = 'Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Age
              _StatInput(
                label: 'Age',
                hint: '25',
                suffix: 'years',
                controller: _ageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Weight
              _StatInput(
                label: 'Weight',
                hint: '70',
                suffix: 'kg',
                controller: _weightController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Height
              _StatInput(
                label: 'Height',
                hint: '175',
                suffix: 'cm',
                controller: _heightController,
                keyboardType: TextInputType.number,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: _isValid ? _onContinue : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatInput extends StatelessWidget {
  final String label;
  final String hint;
  final String suffix;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _StatInput({
    required this.label,
    required this.hint,
    required this.suffix,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
