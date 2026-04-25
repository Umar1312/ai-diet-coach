import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import '../core/di/providers.dart';
import '../shared/models/pantry_models.dart';
import 'dashboard_store.dart';

/// A suggestion item enriched with a local id so the UI can track per-item state.
class SuggestionUiItem {
  final String id;
  final PantrySuggestionItem item;

  SuggestionUiItem({required this.id, required this.item});
}

/// MobX store WITHOUT codegen for the pantry suggestions screen.
class PantrySuggestionsStore {
  final DashboardStore dashboardStore;

  PantrySuggestionsStore({required this.dashboardStore});

  final suggestions = ObservableList<SuggestionUiItem>();
  final isLoading = Observable<bool>(false);
  final errorMessage = Observable<String>('');
  final addingIds = ObservableSet<String>();
  final removingIds = ObservableSet<String>();

  int _idCounter = 0;

  String _generateId() {
    _idCounter++;
    return 'suggestion_$_idCounter';
  }

  Future<void> loadSuggestions() async {
    runInAction(() {
      isLoading.value = true;
      errorMessage.value = '';
    });
    try {
      final response = await apiService.fetchPantrySuggestions(
        page: 1,
        pageSize: 50,
      );
      runInAction(() {
        suggestions
          ..clear()
          ..addAll(
            response.items.map(
              (item) => SuggestionUiItem(id: _generateId(), item: item),
            ),
          );
      });
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(
        () => errorMessage.value =
            'Failed to load suggestions. Please try again.',
      );
    } finally {
      runInAction(() => isLoading.value = false);
    }
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

      runInAction(() => addingIds.remove(id));

      // Let the tick sit for a beat before sliding the item away.
      await Future.delayed(const Duration(milliseconds: 400));

      runInAction(() => removingIds.add(id));
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
    dashboardStore.loadPantry();
  }

  void clearError() {
    runInAction(() => errorMessage.value = '');
  }
}
