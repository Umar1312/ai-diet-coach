import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/router/safe_navigation.dart';
import 'package:diet_coach_ai/features/log_meal/stores/meal_logging_store.dart';
import 'package:diet_coach_ai/main.dart' show mealLoggingStore;
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/presentation/widgets/slot_picker.dart';

class FoodSearchScreen extends StatefulWidget {
  final MealLoggingStore? store;

  const FoodSearchScreen({super.key, this.store});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  MealLoggingStore get _store => widget.store ?? mealLoggingStore;

  @override
  void initState() {
    super.initState();
    _store.resetSearch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 220) {
      unawaited(_store.loadMore());
    }
  }

  void _onSearchChanged(String value) {
    _store.setQuery(value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      unawaited(_store.search());
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_store.search()),
    );
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    _searchController.clear();
    _store.setQuery('');
    unawaited(_store.search());
  }

  Future<void> _reviewFood(FoodItem item) async {
    if (_store.isLogging) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final servings = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortionReviewSheet(item: item),
    );
    if (!mounted || servings == null) return;
    final choice = await showSlotPicker(
      context,
      _store.dashboardStore.plannedMeals,
    );
    if (!mounted || choice == null) return;
    PlannedMeal? replacedSlot;
    if (choice != extraMealChoice) {
      replacedSlot = _store.dashboardStore.plannedMeals
          .where((meal) => meal.id == choice)
          .firstOrNull;
      if (replacedSlot == null) return;
    }
    HapticFeedback.mediumImpact();
    unawaited(
      _store.logFood(item, servings: servings, replacedSlot: replacedSlot),
    );
    context.go('/meal-impact');
  }

  Future<void> _estimateAndReview() async {
    if (_store.isLogging) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final item = await _store.estimateFoodForReview();
    if (!mounted || item == null) return;
    await _reviewFood(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => context.popOrGo('/log')),
                  const SizedBox(height: 24),
                  const Text(
                    'Find what you ate',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search foods, dishes, or drinks. Tap one to log a serving.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Observer(
                    builder: (_) => _SearchField(
                      controller: _searchController,
                      showClear: _store.query.value.isNotEmpty,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: Observer(
                builder: (_) {
                  final query = _store.query.value.trim();
                  final results = _store.results.toList();
                  final error = _store.errorMessage.value;

                  if (query.isEmpty) return const _SearchPrompt();
                  if (_store.isSearching.value && results.isEmpty) {
                    return const _SearchingState();
                  }
                  if (error != null && results.isEmpty) {
                    return _SearchError(
                      message: error,
                      onRetry: () => _store.search(),
                    );
                  }
                  if (results.isEmpty) {
                    return _NoResults(
                      query: query,
                      isEstimating: _store.isEstimating.value,
                      onEstimate: _estimateAndReview,
                    );
                  }

                  return Column(
                    children: [
                      if (_store.isSearching.value)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.textPrimary,
                          backgroundColor: AppColors.surface,
                        ),
                      if (error != null)
                        _InlineError(
                          message: error,
                          onRetry: () => _store.search(),
                        ),
                      Expanded(
                        child: ListView.separated(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                          itemCount:
                              results.length +
                              1 +
                              (_store.isLoadingMore.value ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            if (index < results.length) {
                              final item = results[index];
                              return _FoodResultTile(
                                item: item,
                                isLogging:
                                    _store.loggingFoodId.value == item.id,
                                enabled: !_store.isLogging,
                                onTap: () => _reviewFood(item),
                              );
                            }
                            if (index == results.length) {
                              return _EstimateResult(
                                query: query,
                                isLoading: _store.isEstimating.value,
                                enabled: !_store.isLogging,
                                onTap: _estimateAndReview,
                              );
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onChanged(controller.text),
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        hintText: 'Search food or dish',
        hintStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 22,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: showClear
            ? GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FoodResultTile extends StatelessWidget {
  final FoodItem item;
  final bool isLogging;
  final bool enabled;
  final VoidCallback onTap;

  const _FoodResultTile({
    required this.item,
    required this.isLogging,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled || isLogging ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.servingSize,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.calories} cal  ·  ${item.proteinG}g protein',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isLogging)
                const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2.3),
                )
              else
                const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimateResult extends StatelessWidget {
  final String query;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _EstimateResult({
    required this.query,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fatsLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2.2),
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.fats,
                      size: 21,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Estimating…' : 'Can’t find it?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ask AI to estimate “$query”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      icon: Icons.restaurant_menu_rounded,
      title: 'Start with a food or dish',
      detail: 'Try “paneer wrap”, “coffee”, or “chicken biryani”.',
    );
  }
}

class _SearchingState extends StatelessWidget {
  const _SearchingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final bool isEstimating;
  final VoidCallback onEstimate;

  const _NoResults({
    required this.query,
    required this.isEstimating,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textTertiary,
            size: 38,
          ),
          const SizedBox(height: 16),
          const Text(
            'No exact match',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'AI can estimate one serving from your description.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _EstimateResult(
            query: query,
            isLoading: isEstimating,
            enabled: !isEstimating,
            onTap: onEstimate,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SearchError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.textTertiary,
            size: 38,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Try again',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(28, 4, 28, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$message Tap to retry.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 29),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionReviewSheet extends StatefulWidget {
  final FoodItem item;

  const _PortionReviewSheet({required this.item});

  @override
  State<_PortionReviewSheet> createState() => _PortionReviewSheetState();
}

class _PortionReviewSheetState extends State<_PortionReviewSheet> {
  double _servings = 1;

  int _scaled(int value) => (value * _servings).round();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isEstimate = item.source == 'ai' || item.source == 'estimate';
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '${item.emoji} ${item.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEstimate
                  ? 'Estimated nutrition — confirm the portion before saving.'
                  : 'Confirm the portion you actually ate.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _PortionButton(
                    icon: Icons.remove_rounded,
                    enabled: _servings > 0.5,
                    onTap: () => setState(() => _servings -= 0.5),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_servings.toStringAsFixed(_servings % 1 == 0 ? 0 : 1)} × ${item.servingSize}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_scaled(item.calories)} cal · ${_scaled(item.proteinG)}g protein',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PortionButton(
                    icon: Icons.add_rounded,
                    enabled: _servings < 10,
                    onTap: () => setState(() => _servings += 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _servings);
              },
              child: Container(
                height: 64,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Confirm Portion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PortionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
