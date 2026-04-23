import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  final _store = onboardingStore;
  String? _selectedLevel;

  final List<Map<String, dynamic>> _levels = [
    {
      'title': 'Sedentary',
      'subtitle': 'Little to no exercise',
      'icon': Icons.weekend,
    },
    {
      'title': 'Lightly Active',
      'subtitle': 'Light exercise 1-3 days/week',
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Moderately Active',
      'subtitle': 'Moderate exercise 3-5 days/week',
      'icon': Icons.directions_run,
    },
    {
      'title': 'Very Active',
      'subtitle': 'Hard exercise 6-7 days/week',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Extremely Active',
      'subtitle': 'Very hard exercise & physical job',
      'icon': Icons.sports,
    },
  ];

  void _onContinue() {
    if (_selectedLevel != null) {
      final apiValue = AppConstants.activityLevelMap[_selectedLevel!];
      _store.updateUser(activityLevel: apiValue?.toString());
      context.push('/onboarding/goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const OnboardingProgressBar(step: 5, totalSteps: 8),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'How active\nare you?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final isSelected = _selectedLevel == level['title'];
                    return _ActivityCard(
                      icon: level['icon'],
                      title: level['title'],
                      subtitle: level['subtitle'],
                      isSelected: isSelected,
                      onTap: () =>
                          setState(() => _selectedLevel = level['title']),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Continue',
                onPressed: _selectedLevel != null ? _onContinue : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
