import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';

/// Bottom sheet for picking one atomic food item for a day-plan slot.
Future<MealComponent?> showSlotMealPickerSheet(BuildContext context) async {
  return showModalBottomSheet<MealComponent?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SlotMealPickerSheet(),
  );
}

class _SlotMealPickerSheet extends StatefulWidget {
  const _SlotMealPickerSheet();

  @override
  State<_SlotMealPickerSheet> createState() => _SlotMealPickerSheetState();
}

class _SlotMealPickerSheetState extends State<_SlotMealPickerSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _suggestions = <FoodItem>[];
  final _quantitiesById = <String, int>{};
  var _isLoading = false;
  var _isLoadingMore = false;
  var _isEstimating = false;
  var _hasMore = true;
  var _errorMessage = '';
  var _currentPage = 1;
  var _hasPendingSearch = false;
  Timer? _debounceTimer;

  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadSuggestions({bool append = false}) async {
    if (_isLoading || _isLoadingMore) {
      if (!append) _hasPendingSearch = true;
      return;
    }
    if (append && !_hasMore) return;

    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _suggestions.clear();
          _hasMore = false;
        });
        return;
      }

      final response = await apiService.searchFoods(
        page: _currentPage,
        pageSize: _pageSize,
        q: query,
      );

      if (!mounted) return;
      if (!append && query != _searchController.text.trim()) {
        _hasPendingSearch = true;
        return;
      }

      setState(() {
        if (append) {
          _suggestions.addAll(response.items);
        } else {
          _suggestions
            ..clear()
            ..addAll(response.items);
        }

        if (response.items.length < _pageSize) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load suggestions.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      if (_hasPendingSearch) {
        _hasPendingSearch = false;
        unawaited(_loadSuggestions());
      }
    }
  }

  Future<void> _loadMore() async {
    await _loadSuggestions(append: true);
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadSuggestions();
    });
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _searchController.clear();
    _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Add item',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Search foods and servings.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Search foods...',
                hintStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 16, left: 8),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading && _suggestions.isNotEmpty)
            const _SearchLoadingIndicator(),
          if (_errorMessage.isNotEmpty) _buildErrorBanner(),
          if (_isLoading && _suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator.adaptive(),
            )
          else if (_suggestions.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(28),
              child: _searchController.text.trim().isEmpty
                  ? const Text(
                      'Start typing to search',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : _EstimateFoodAction(
                      query: _searchController.text.trim(),
                      isLoading: _isEstimating,
                      onTap: _estimateCurrentQuery,
                    ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                itemCount:
                    _suggestions.length +
                    (_shouldShowEstimateAction ? 1 : 0) +
                    (_isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  if (index < _suggestions.length) {
                    final item = _suggestions[index];
                    return _SuggestionTile(
                      item: item,
                      quantity: _quantityFor(item),
                      onDecrease: () => _decrementQuantity(item),
                      onIncrease: () => _incrementQuantity(item),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(
                          context,
                          item.toComponent(
                            quantity: _quantityFor(item).toDouble(),
                          ),
                        );
                      },
                    );
                  }

                  final estimateIndex = _suggestions.length;
                  if (_shouldShowEstimateAction && index == estimateIndex) {
                    return _EstimateFoodAction(
                      query: _searchController.text.trim(),
                      isLoading: _isEstimating,
                      onTap: _estimateCurrentQuery,
                    );
                  }

                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool get _shouldShowEstimateAction =>
      _searchController.text.trim().length >= 2 && !_isLoading;

  Future<void> _estimateCurrentQuery() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _isEstimating) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isEstimating = true;
      _errorMessage = '';
    });

    try {
      final item = await apiService.estimateFood(query);
      if (!mounted) return;
      Navigator.pop(context, item.toComponent());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to estimate this item.');
    } finally {
      if (mounted) {
        setState(() => _isEstimating = false);
      }
    }
  }

  int _quantityFor(FoodItem item) => _quantitiesById[item.id] ?? 1;

  void _incrementQuantity(FoodItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _quantityFor(item);
      if (current < 20) {
        _quantitiesById[item.id] = current + 1;
      }
    });
  }

  void _decrementQuantity(FoodItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _quantityFor(item);
      if (current > 1) {
        _quantitiesById[item.id] = current - 1;
      }
    });
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchLoadingIndicator extends StatelessWidget {
  const _SearchLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Searching...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateFoodAction extends StatelessWidget {
  final String query;
  final bool isLoading;
  final VoidCallback onTap;

  const _EstimateFoodAction({
    required this.query,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Estimating item...' : 'Estimate "$query"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'One estimated serving',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.item,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final calories = item.calories * quantity;
    final protein = item.proteinG * quantity;
    final carbs = item.carbsG * quantity;
    final fats = item.fatsG * quantity;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quantity == 1
                        ? item.servingSize
                        : '$quantity x ${item.servingSize}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _DotValue(color: AppColors.protein, value: '${protein}g'),
                      const SizedBox(width: 12),
                      _DotValue(color: AppColors.carbs, value: '${carbs}g'),
                      const SizedBox(width: 12),
                      _DotValue(color: AppColors.fats, value: '${fats}g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$calories cal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.calories,
                  ),
                ),
                const SizedBox(height: 10),
                _ResultQuantityStepper(
                  quantity: quantity,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ResultQuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            isEnabled: quantity > 1,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            isEnabled: quantity < 20,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onTap : null,
      child: SizedBox(
        width: 32,
        height: 34,
        child: Icon(
          icon,
          color: isEnabled ? AppColors.textPrimary : AppColors.textTertiary,
          size: 18,
        ),
      ),
    );
  }
}

class _DotValue extends StatelessWidget {
  final Color color;
  final String value;

  const _DotValue({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
