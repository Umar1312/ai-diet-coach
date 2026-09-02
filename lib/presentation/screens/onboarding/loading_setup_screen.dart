import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';
import '../../widgets/progress_bar.dart';

class LoadingSetupScreen extends StatefulWidget {
  const LoadingSetupScreen({super.key});

  @override
  State<LoadingSetupScreen> createState() => _LoadingSetupScreenState();
}

class _LoadingSetupScreenState extends State<LoadingSetupScreen> {
  bool _setupFailed = false;

  final List<Map<String, dynamic>> _checklistItems = [
    {'label': 'Calories', 'checked': false},
    {'label': 'Carbs', 'checked': false},
    {'label': 'Protein', 'checked': false},
    {'label': 'Fats', 'checked': false},
    {'label': 'Food preferences', 'checked': false},
  ];

  @override
  void initState() {
    super.initState();
    _startCalculation();
  }

  Future<void> _startCalculation() async {
    setState(() {
      _setupFailed = false;
      for (final item in _checklistItems) {
        item['checked'] = false;
      }
    });

    try {
      final response = await onboardingStore.calculatePlan();
      // Keep the targets returned by setup available immediately. The full
      // pantry-aware day plan is generated after the pantry decision.
      dashboardStore.applyPlan(response.plan);
      authStore.markProfileSetupComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _setupFailed = true;
        });
        runInAction(() {
          onboardingStore.loadingStatus =
              'We could not create your targets. Check your connection and try again.';
          onboardingStore.loadingProgress = 0.0;
        });
      }
      return;
    }

    for (int i = 0; i < _checklistItems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _checklistItems[i]['checked'] = true;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.pushReplacement('/onboarding/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      Observer(
                        builder: (_) => Text(
                          '${(onboardingStore.loadingProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We're setting everything\nup for you",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      Observer(
                        builder: (_) => ProgressBar(
                          progress: onboardingStore.loadingProgress,
                          height: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Observer(
                        builder: (_) => Text(
                          onboardingStore.loadingStatus,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Daily recommendation for',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._checklistItems.map(
                        (item) => _ChecklistItem(
                          label: item['label'],
                          isChecked: item['checked'],
                        ),
                      ),
                      const Spacer(),
                      if (_setupFailed) ...[
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _startCalculation();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Try again',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool isChecked;

  const _ChecklistItem({required this.label, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '• $label',
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isChecked ? AppColors.success : AppColors.border,
                width: 2,
              ),
            ),
            child: isChecked
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textOnPrimary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
