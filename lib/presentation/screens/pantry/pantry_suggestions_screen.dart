import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show pantrySuggestionsStore;
import 'package:diet_coach_ai/stores/pantry_suggestions_store.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';

class PantrySuggestionsScreen extends StatefulWidget {
  const PantrySuggestionsScreen({super.key});

  @override
  State<PantrySuggestionsScreen> createState() =>
      _PantrySuggestionsScreenState();
}

class _PantrySuggestionsScreenState extends State<PantrySuggestionsScreen> {
  late final PantrySuggestionsStore _store;
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _store = pantrySuggestionsStore;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController();
    _store.loadSuggestions();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _store.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            return Column(
              children: [
                const _Header(),
                _SearchBar(controller: _searchController, store: _store),
                if (_store.errorMessage.value.isNotEmpty) _buildErrorBanner(),
                if (_store.isLoading.value && _store.suggestions.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                Expanded(
                  child: _store.isLoading.value && _store.suggestions.isEmpty
                      ? _buildLoading()
                      : _store.suggestions.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          itemCount:
                              _store.suggestions.length +
                              (_store.isLoadingMore.value ? 1 : 0) +
                              (_store.hasMore && !_store.isLoadingMore.value
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            if (index < _store.suggestions.length) {
                              final uiItem = _store.suggestions[index];
                              return _SuggestionTile(
                                key: ValueKey(uiItem.id),
                                store: _store,
                                uiItem: uiItem,
                              );
                            }
                            if (_store.isLoadingMore.value &&
                                index == _store.suggestions.length) {
                              return _buildLoadMoreIndicator();
                            }
                            return _buildLoadMoreButton();
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 12),
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
              _store.errorMessage.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: _store.clearError,
            child: const Icon(Icons.close, color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _store.loadMore();
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Load more suggestions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final hasQuery = _store.searchQuery.value.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery
                ? 'No suggestions found for "${_store.searchQuery.value.trim()}"'
                : 'No suggestions available',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Add to Pantry',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final PantrySuggestionsStore store;

  const _SearchBar({required this.controller, required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
      child: Observer(
        builder: (_) {
          return TextField(
            controller: controller,
            onChanged: store.setSearchQuery,
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
              suffixIcon: store.searchQuery.value.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.clear();
                        store.clearSearch();
                      },
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
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final PantrySuggestionsStore store;
  final SuggestionUiItem uiItem;

  const _SuggestionTile({super.key, required this.store, required this.uiItem});

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _removeController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final ReactionDisposer _removeReaction;

  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _removeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(parent: _removeController, curve: Curves.easeInOut),
        );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _removeController, curve: Curves.easeInOut),
    );

    _removeController.addStatusListener(_onRemoveStatusChanged);

    _removeReaction = autorun((_) {
      if (widget.store.removingIds.contains(widget.uiItem.id) &&
          !_isRemoving &&
          mounted) {
        _isRemoving = true;
        _removeController.forward();
      }
    });
  }

  void _onRemoveStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.store.confirmRemoval(widget.uiItem.id);
    }
  }

  @override
  void dispose() {
    _removeReaction();
    _removeController.removeStatusListener(_onRemoveStatusChanged);
    _removeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                widget.uiItem.item.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.uiItem.item.name,
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
                    _MacroDots(item: widget.uiItem.item),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AddButton(store: widget.store, id: widget.uiItem.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroDots extends StatelessWidget {
  final PantrySuggestionItem item;

  const _MacroDots({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DotValue(color: AppColors.protein, value: '${item.proteinG}g'),
        const SizedBox(width: 12),
        _DotValue(color: AppColors.carbs, value: '${item.carbsG}g'),
        const SizedBox(width: 12),
        _DotValue(color: AppColors.fats, value: '${item.fatsG}g'),
      ],
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final PantrySuggestionsStore store;
  final String id;

  const _AddButton({required this.store, required this.id});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isAdding = store.addingIds.contains(id);
        final isRemoving = store.removingIds.contains(id);

        return GestureDetector(
          onTap: isAdding || isRemoving
              ? null
              : () async {
                  HapticFeedback.mediumImpact();
                  await store.addItem(id);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAdding
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: isAdding
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('tick'),
                      color: AppColors.success,
                      size: 22,
                    )
                  : const Icon(
                      Icons.add_rounded,
                      key: ValueKey('plus'),
                      color: AppColors.primary,
                      size: 22,
                    ),
            ),
          ),
        );
      },
    );
  }
}
