import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../main.dart' show dashboardStore, cravingStore;
import '../../../shared/models/home_models.dart';
import 'stores/craving_store.dart';
import 'widgets/streaming_text_lines.dart';

/// Bottom sheet that walks the user through craving → AI thinking → snack reveal.
class CravingSheet extends StatelessWidget {
  const CravingSheet({super.key});

  // Placeholder Lottie URL — swap with your preferred sparkle/AI animation.
  static const String _lottieUrl =
      'https://assets2.lottiefiles.com/packages/lf20_usmfx6bp.json';

  static const List<Map<String, String>> _tags = [
    {'emoji': '🍫', 'label': 'Sweet', 'value': 'sweet'},
    {'emoji': '🧂', 'label': 'Salty', 'value': 'salty'},
    {'emoji': '🌶', 'label': 'Spicy', 'value': 'spicy'},
    {'emoji': '🥨', 'label': 'Crunchy', 'value': 'crunchy'},
    {'emoji': '🍦', 'label': 'Creamy', 'value': 'creamy'},
    {'emoji': '🥛', 'label': 'Light', 'value': 'light'},
    {'emoji': '🍔', 'label': 'Indulgent', 'value': 'indulgent'},
    {'emoji': '🥶', 'label': 'Cold', 'value': 'cold'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: Observer(
              builder: (_) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPhase(context),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    switch (cravingStore.phase.value) {
      case CravingPhase.prompt:
        return _PromptView(tags: _tags, key: const ValueKey('prompt'));
      case CravingPhase.thinking:
        return _ThinkingView(
          lottieUrl: _lottieUrl,
          key: const ValueKey('thinking'),
        );
      case CravingPhase.reveal:
        return _RevealView(key: const ValueKey('reveal'));
      case CravingPhase.error:
        return _ErrorView(key: const ValueKey('error'));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Prompt View
// ═══════════════════════════════════════════════════════════════════════════

class _PromptView extends StatelessWidget {
  final List<Map<String, String>> tags;

  const _PromptView({required this.tags, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GrabHandle(),
        const SizedBox(height: 28),
        const Text(
          'What are you craving?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Observer(
          builder: (_) {
            final cal = dashboardStore.caloriesLeft.value;
            final protein = dashboardStore.proteinLeft.value;
            final lowCal = cal <= 50;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lowCal
                      ? "You've nearly hit your goal — we'll suggest something small and light."
                      : '$cal cal · ${protein}g protein left',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: lowCal
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (lowCal) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Small portions only from here',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _CravingInput(),
        const SizedBox(height: 16),
        _TagChips(tags: tags),
        const SizedBox(height: 24),
        Observer(
          builder: (_) {
            final canSubmit = cravingStore.canSubmit.value;
            return GestureDetector(
              onTap: canSubmit
                  ? () {
                      HapticFeedback.mediumImpact();
                      cravingStore.requestCraving(
                        preferPantry: dashboardStore.pantry.isNotEmpty,
                      );
                    }
                  : null,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: canSubmit ? AppColors.textPrimary : AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Find me something',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CravingInput extends StatefulWidget {
  @override
  State<_CravingInput> createState() => _CravingInputState();
}

class _CravingInputState extends State<_CravingInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: cravingStore.cravingText.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: _controller,
        onChanged: cravingStore.setText,
        maxLines: 3,
        minLines: 1,
        maxLength: 200,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => const SizedBox.shrink(),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          hintText: 'chocolate, salty, crunchy…',
          hintStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  final List<Map<String, String>> tags;

  const _TagChips({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Observer(
          builder: (_) {
            final isSelected = cravingStore.selectedTags.contains(tag['value']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                cravingStore.toggleTag(tag['value']!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${tag['emoji']} ${tag['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Thinking View
// ═══════════════════════════════════════════════════════════════════════════

class _ThinkingView extends StatelessWidget {
  final String lottieUrl;

  const _ThinkingView({required this.lottieUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _GrabHandle(),
        const SizedBox(height: 40),
        SizedBox(
          width: 220,
          height: 220,
          child: Lottie.network(
            lottieUrl,
            repeat: true,
            errorBuilder: (context, error, stackTrace) => const _FallbackOrb(),
          ),
        ),
        const SizedBox(height: 32),
        const StreamingTextLines(
          lines: [
            'Reading your craving…',
            'Checking your remaining macros…',
            'Finding the perfect match…',
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

/// Beautiful fallback when Lottie fails to load.
class _FallbackOrb extends StatefulWidget {
  const _FallbackOrb();

  @override
  State<_FallbackOrb> createState() => _FallbackOrbState();
}

class _FallbackOrbState extends State<_FallbackOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.9 + (_controller.value * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppColors.calories.withValues(alpha: 0.4),
                  AppColors.protein.withValues(alpha: 0.4),
                  AppColors.carbs.withValues(alpha: 0.4),
                  AppColors.fats.withValues(alpha: 0.4),
                  AppColors.calories.withValues(alpha: 0.4),
                ],
                transform: GradientRotation(_controller.value * 2 * 3.14159),
              ),
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reveal View
// ═══════════════════════════════════════════════════════════════════════════

class _RevealView extends StatelessWidget {
  const _RevealView({super.key});

  @override
  Widget build(BuildContext context) {
    final meal = cravingStore.result.value;
    if (meal == null) return const SizedBox.shrink();

    // Haptic on reveal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _GrabHandle(),
        const SizedBox(height: 24),
        Text(meal.emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text(
          meal.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            meal.whyItFits,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        _MacroPills(meal: meal),
        const SizedBox(height: 16),
        if (meal.usedPantryItems.isNotEmpty)
          _PantryBadge(
            items: meal.usedPantryItems,
            reasoning: meal.pantryReasoning,
          ),
        const SizedBox(height: 28),
        Observer(
          builder: (_) {
            final isLogging = cravingStore.isLogging.value;
            return GestureDetector(
              onTap: isLogging
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final response = await cravingStore.logChosen();
                      if (response != null) {
                        dashboardStore.applyPlan(response.updatedPlan);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showLoggedSnack(context);
                      }
                    },
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: isLogging
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Log it',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            cravingStore.tryAgain(
              preferPantry: dashboardStore.pantry.isNotEmpty,
            );
          },
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            child: const Text(
              'Try another',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLoggedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Logged!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPills extends StatelessWidget {
  final NextMealRecommendation meal;

  const _MacroPills({required this.meal});

  @override
  Widget build(BuildContext context) {
    final items = [
      _PillData(
        label: '${meal.calories}',
        unit: 'cal',
        color: AppColors.calories,
      ),
      _PillData(
        label: '${meal.proteinG}g',
        unit: 'P',
        color: AppColors.protein,
      ),
      _PillData(label: '${meal.carbsG}g', unit: 'C', color: AppColors.carbs),
      _PillData(label: '${meal.fatsG}g', unit: 'F', color: AppColors.fats),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Row(
          children: [
            if (i > 0) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.unit,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PillData {
  final String label;
  final String unit;
  final Color color;
  _PillData({required this.label, required this.unit, required this.color});
}

class _PantryBadge extends StatelessWidget {
  final List<String> items;
  final String? reasoning;

  const _PantryBadge({required this.items, this.reasoning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🥫', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reasoning ?? 'Uses ${items.join(', ')}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error View
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _GrabHandle(),
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Observer(
          builder: (_) => Text(
            cravingStore.errorMessage.value ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            cravingStore.requestCraving(
              preferPantry: dashboardStore.pantry.isNotEmpty,
            );
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
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            cravingStore.reset();
          },
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            child: const Text(
              'Start over',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared
// ═══════════════════════════════════════════════════════════════════════════

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
