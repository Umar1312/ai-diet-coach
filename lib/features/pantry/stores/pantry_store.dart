import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';

import '../../../core/di/providers.dart';
import '../../../shared/models/home_models.dart';
import '../../../shared/models/pantry_models.dart';
import '../../../stores/dashboard_store.dart';

/// MobX store WITHOUT codegen for pantry management and onboarding.
class PantryStore {
  final DashboardStore? dashboardStore;

  PantryStore({this.dashboardStore});
  // ── Pantry list ─────────────────────────────────────────────────────────

  final items = ObservableList<PantryItem>();
  final isLoading = Observable<bool>(false);
  final errorMessage = Observable<String>('');

  // ── Starter pack onboarding ─────────────────────────────────────────────

  final starterPack = ObservableList<PantryStarterItem>();
  final selectedStarterNames = ObservableSet<String>();
  final isLoadingStarter = Observable<bool>(false);
  final starterError = Observable<String>('');
  final isBulkAdding = Observable<bool>(false);

  // ── Computed ────────────────────────────────────────────────────────────

  late final selectedCount = Computed<int>(() => selectedStarterNames.length);

  late final groupedStarters = Computed<Map<String, List<PantryStarterItem>>>(
    () {
      final map = <String, List<PantryStarterItem>>{};
      for (final item in starterPack) {
        map.putIfAbsent(item.category, () => []).add(item);
      }
      return map;
    },
  );

  // ── Actions: Pantry ─────────────────────────────────────────────────────

  Future<void> loadPantry() async {
    runInAction(() {
      isLoading.value = true;
      errorMessage.value = '';
    });
    try {
      final response = await apiService.fetchPantry();
      final pantryItems = response.items.map(PantryItem.fromResponse).toList();
      runInAction(() {
        items
          ..clear()
          ..addAll(pantryItems);
      });
      // Sync to dashboard store so other features see the latest pantry
      if (dashboardStore != null) {
        runInAction(() {
          dashboardStore!.pantry
            ..clear()
            ..addAll(pantryItems);
        });
      }
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(() => errorMessage.value = 'Failed to load pantry.');
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await apiService.deletePantryItem(id);
      HapticFeedback.lightImpact();
      await loadPantry();
      // Refresh dashboard so AI recalculates without the deleted item.
      if (dashboardStore != null) {
        final plan = await apiService.fetchDashboard(
          preferPantry: items.isNotEmpty,
        );
        dashboardStore!.applyPlan(plan);
      }
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(() => errorMessage.value = 'Failed to delete item.');
    }
  }

  Future<void> addItem(PantryCreateRequest request) async {
    try {
      await apiService.addPantryItem(request);
      HapticFeedback.mediumImpact();
      await loadPantry();
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(() => errorMessage.value = 'Failed to add item.');
    }
  }

  // ── Actions: Starter Pack ───────────────────────────────────────────────

  Future<void> loadStarterPack() async {
    runInAction(() {
      isLoadingStarter.value = true;
      starterError.value = '';
      selectedStarterNames.clear();
    });
    try {
      final response = await apiService.fetchStarterPack();
      runInAction(() {
        starterPack
          ..clear()
          ..addAll(response.items);
      });
    } on ApiException catch (e) {
      runInAction(() => starterError.value = e.message);
    } catch (e) {
      runInAction(() => starterError.value = 'Failed to load starter pack.');
    } finally {
      runInAction(() => isLoadingStarter.value = false);
    }
  }

  void toggleStarterItem(String name) {
    runInAction(() {
      if (selectedStarterNames.contains(name)) {
        selectedStarterNames.remove(name);
      } else {
        selectedStarterNames.add(name);
      }
    });
  }

  void selectAllInCategory(String category) {
    runInAction(() {
      for (final item in starterPack) {
        if (item.category == category) {
          selectedStarterNames.add(item.name);
        }
      }
    });
  }

  void deselectAllInCategory(String category) {
    runInAction(() {
      for (final item in starterPack) {
        if (item.category == category) {
          selectedStarterNames.remove(item.name);
        }
      }
    });
  }

  bool isCategoryFullySelected(String category) {
    final categoryItems = starterPack.where((i) => i.category == category);
    if (categoryItems.isEmpty) return false;
    return categoryItems.every((i) => selectedStarterNames.contains(i.name));
  }

  Future<void> addSelectedStarters() async {
    final toAdd = starterPack
        .where((i) => selectedStarterNames.contains(i.name))
        .toList();

    if (toAdd.isEmpty) return;

    runInAction(() => isBulkAdding.value = true);
    try {
      for (final item in toAdd) {
        await apiService.addPantryItem(item.toCreateRequest());
      }
      HapticFeedback.mediumImpact();
      selectedStarterNames.clear();
      await loadPantry();
    } on ApiException catch (e) {
      runInAction(() => starterError.value = e.message);
    } catch (e) {
      runInAction(() => starterError.value = 'Failed to add items.');
    } finally {
      runInAction(() => isBulkAdding.value = false);
    }
  }

  void clearStarterError() {
    runInAction(() => starterError.value = '');
  }

  void clearError() {
    runInAction(() => errorMessage.value = '');
  }
}
