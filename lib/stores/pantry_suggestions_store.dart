import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import '../core/di/providers.dart';
import '../shared/models/pantry_models.dart';
import '../features/pantry/stores/pantry_store.dart';

/// A suggestion item enriched with a local id so the UI can track per-item state.
class SuggestionUiItem {
  final String id;
  final PantrySuggestionItem item;

  SuggestionUiItem({required this.id, required this.item});
}

/// MobX store WITHOUT codegen for the pantry suggestions screen.
class PantrySuggestionsStore {
  final PantryStore pantryStore;

  PantrySuggestionsStore({required this.pantryStore});

  final suggestions = ObservableList<SuggestionUiItem>();
  final isLoading = Observable<bool>(false);
  final isLoadingMore = Observable<bool>(false);
  final errorMessage = Observable<String>('');
  final addingIds = ObservableSet<String>();
  final removingIds = ObservableSet<String>();

  int _currentPage = 1;
  static const int _pageSize = 15;
  bool _reachedEnd = false;

  int _idCounter = 0;

  String _generateId() {
    _idCounter++;
    return 'suggestion_$_idCounter';
  }

  bool get hasMore => !_reachedEnd && !isLoadingMore.value;

  Future<void> loadSuggestions({bool append = false}) async {
    if (isLoadingMore.value || isLoading.value) {
      debugPrint(
        '[PantrySuggestions] blocked: loading=${isLoading.value}, loadingMore=${isLoadingMore.value}',
      );
      return;
    }

    if (append && _reachedEnd) {
      debugPrint('[PantrySuggestions] blocked: reached end');
      return;
    }

    if (append) {
      runInAction(() => isLoadingMore.value = true);
    } else {
      runInAction(() {
        isLoading.value = true;
        errorMessage.value = '';
      });
      _currentPage = 1;
      _reachedEnd = false;
    }

    debugPrint(
      '[PantrySuggestions] fetching page=$_currentPage, append=$append',
    );

    try {
      final response = await apiService.fetchPantrySuggestions(
        page: _currentPage,
        pageSize: _pageSize,
      );

      debugPrint(
        '[PantrySuggestions] received ${response.items.length} items, total=${response.total}',
      );

      runInAction(() {
        final newItems = response.items
            .map((item) => SuggestionUiItem(id: _generateId(), item: item))
            .toList();

        if (newItems.isEmpty) {
          _reachedEnd = true;
          debugPrint('[PantrySuggestions] reached end (empty page)');
        } else {
          if (append) {
            suggestions.addAll(newItems);
          } else {
            suggestions
              ..clear()
              ..addAll(newItems);
          }
          _currentPage++;
          debugPrint(
            '[PantrySuggestions] appended, next page=$_currentPage, total stored=${suggestions.length}',
          );
        }
      });
    } on ApiException catch (e) {
      debugPrint('[PantrySuggestions] API error: ${e.message}');
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      debugPrint('[PantrySuggestions] error: $e');
      runInAction(
        () => errorMessage.value =
            'Failed to load suggestions. Please try again.',
      );
    } finally {
      runInAction(() {
        isLoading.value = false;
        isLoadingMore.value = false;
      });
    }
  }

  Future<void> loadMore() async {
    await loadSuggestions(append: true);
  }

  Future<void> addItem(String id) async {
    final uiItem = suggestions.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Item $id not found'),
    );

    runInAction(() => addingIds.add(id));

    try {
      final item = uiItem.item;
      await apiService.addPantryItem(
        PantryCreateRequest(
          name: item.name,
          emoji: item.emoji,
          calories: item.calories,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatsG: item.fatsG,
          servingSize: item.servingSize,
        ),
      );

      HapticFeedback.lightImpact();

      // Let the tick sit for a beat before sliding the item away.
      await Future.delayed(const Duration(milliseconds: 400));

      runInAction(() {
        addingIds.remove(id);
        removingIds.add(id);
      });
    } on ApiException catch (e) {
      runInAction(() {
        addingIds.remove(id);
        errorMessage.value = e.message;
      });
    } catch (e) {
      runInAction(() {
        addingIds.remove(id);
        errorMessage.value = 'Something went wrong. Please try again.';
      });
    }
  }

  void confirmRemoval(String id) {
    runInAction(() {
      removingIds.remove(id);
      suggestions.removeWhere((s) => s.id == id);
    });
    // Refresh pantry so the newly added item appears on the pantry tab.
    pantryStore.loadPantry();
  }

  void clearError() {
    runInAction(() => errorMessage.value = '');
  }
}
