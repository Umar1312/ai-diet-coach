import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/presentation/widgets/primary_button.dart';

class TextLogScreen extends StatefulWidget {
  const TextLogScreen({super.key});

  @override
  State<TextLogScreen> createState() => _TextLogScreenState();
}

class _TextLogScreenState extends State<TextLogScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        title: const Text('Describe your meal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.aiGlow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.aiGlow.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.aiGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Our AI will estimate the macros from your description',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.aiGlow,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What did you eat?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., two scrambled eggs with toast and avocado',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(label: 'Chicken breast'),
                  _QuickChip(label: 'Rice bowl'),
                  _QuickChip(label: 'Oatmeal'),
                  _QuickChip(label: 'Protein shake'),
                  _QuickChip(label: 'Salad'),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Log Meal',
                onPressed: _controller.text.trim().isNotEmpty && !_isSubmitting
                    ? () {
                        setState(() => _isSubmitting = true);
                        HapticFeedback.mediumImpact();
                        context.go('/home');
                      }
                    : null,
                isLoading: _isSubmitting,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;

  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
