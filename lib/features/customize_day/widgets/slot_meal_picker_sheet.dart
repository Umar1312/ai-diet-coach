import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';

/// Bottom sheet for picking a meal for a day-plan slot.
/// Searches the common-meal / pantry-suggestions database; backend uses LLM
/// to create new suggestions when a query has no direct matches.
Future<PantrySuggestionItem?> showSlotMealPickerSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<PantrySuggestionItem?>(
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
  final _suggestions = <PantrySuggestionItem>[];
  var _isLoading = false;
  var _isLoadingMore = false;
  var _hasMore = true;
  var _errorMessage = '';
  var _currentPage = 1;
  Timer? _debounceTimer;

  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _loadSuggestions();
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
    if (_isLoading || _isLoadingMore) return;
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
      final response = await apiService.fetchPantrySuggestions(
        page: _currentPage,
        pageSize: _pageSize,
        q: query.isEmpty ? null : query,
      );

      if (!mounted) return;
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
      child: SafeArea(
        top: false,
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
                'Pick a meal',
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
                'Search our meal database. Can\'t find it? Type the name and we\'ll generate it.',
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
                  hintText: 'Search meals...',
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
            if (_errorMessage.isNotEmpty) _buildErrorBanner(),
            if (_isLoading && _suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_suggestions.isEmpty && !_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Start typing to search',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
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
                  itemCount: _suggestions.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    if (index == _suggestions.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }
                    final item = _suggestions[index];
                    return _SuggestionTile(
                      item: item,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, item);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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

class _SuggestionTile extends StatelessWidget {
  final PantrySuggestionItem item;
  final VoidCallback onTap;

  const _SuggestionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _DotValue(
                        color: AppColors.protein,
                        value: '${item.proteinG}g',
                      ),
                      const SizedBox(width: 12),
                      _DotValue(
                        color: AppColors.carbs,
                        value: '${item.carbsG}g',
                      ),
                      const SizedBox(width: 12),
                      _DotValue(color: AppColors.fats, value: '${item.fatsG}g'),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${item.calories} cal',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.calories,
              ),
            ),
          ],
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
