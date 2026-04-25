import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show textLogStore;

class TextLogScreen extends StatefulWidget {
  const TextLogScreen({super.key});

  @override
  State<TextLogScreen> createState() => _TextLogScreenState();
}

class _TextLogScreenState extends State<TextLogScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    textLogStore.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String value) {
    textLogStore.setDescription(value);
  }

  void _insertQuickChip(String label) {
    HapticFeedback.selectionClick();
    final current = _controller.text.trim();
    final separator = current.isEmpty ? '' : ', ';
    final updated = '$current$separator$label';
    _controller.text = updated;
    _controller.selection = TextSelection.collapsed(offset: updated.length);
    textLogStore.setDescription(updated);
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    await textLogStore.submit();

    if (mounted && textLogStore.errorMessage.value == null) {
      _showLoggedSnack(context);
      context.go('/home');
    }
  }

  void _showLoggedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: AppColors.textPrimary,
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logged!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _CloseButton(),
              const SizedBox(height: 32),
              const Text(
                'What did you eat?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Describe your meal and our AI will estimate the macros.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _TextInput(
                controller: _controller,
                onChanged: _onDescriptionChanged,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    label: 'Chicken breast',
                    onTap: () => _insertQuickChip('Chicken breast'),
                  ),
                  _QuickChip(
                    label: 'Rice bowl',
                    onTap: () => _insertQuickChip('Rice bowl'),
                  ),
                  _QuickChip(
                    label: 'Oatmeal',
                    onTap: () => _insertQuickChip('Oatmeal'),
                  ),
                  _QuickChip(
                    label: 'Protein shake',
                    onTap: () => _insertQuickChip('Protein shake'),
                  ),
                  _QuickChip(
                    label: 'Salad',
                    onTap: () => _insertQuickChip('Salad'),
                  ),
                ],
              ),
              Observer(
                builder: (_) {
                  final error = textLogStore.errorMessage.value;
                  if (error == null || error.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Observer(
                builder: (_) {
                  return SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: textLogStore.canSubmit.value ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textTertiary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      child: textLogStore.isSubmitting.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Log Meal'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Close Button
// ═══════════════════════════════════════════════════════════════════════════

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Text Input
// ═══════════════════════════════════════════════════════════════════════════

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _TextInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        autofocus: true,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'e.g., two scrambled eggs with toast and avocado',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Quick Chip
// ═══════════════════════════════════════════════════════════════════════════

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
