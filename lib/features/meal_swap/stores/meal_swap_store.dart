import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/features/meal_swap/models/meal_swap_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

class MealSwapStore {
  final ApiService apiService;
  final DashboardStore dashboardStore;

  final activeMeal = Observable<PlannedMeal?>(null);
  final alternatives = ObservableList<MealAlternative>();
  final selectedReason = Observable<MealSwapReason>(MealSwapReason.surpriseMe);
  final selectedMeal = Observable<Meal?>(null);
  final isLoading = Observable<bool>(false);
  final isApplying = Observable<bool>(false);
  final errorMessage = Observable<String?>(null);
  int _requestVersion = 0;

  MealSwapStore({required this.apiService, required this.dashboardStore});

  Future<void> begin(PlannedMeal meal) async {
    runInAction(() {
      activeMeal.value = meal;
      alternatives.clear();
      selectedReason.value = MealSwapReason.surpriseMe;
      selectedMeal.value = null;
      errorMessage.value = null;
    });
    await loadAlternatives();
  }

  Future<void> chooseReason(MealSwapReason reason) async {
    if (selectedReason.value == reason && alternatives.isNotEmpty) return;
    runInAction(() {
      selectedReason.value = reason;
      selectedMeal.value = null;
    });
    await loadAlternatives();
  }

  Future<void> loadAlternatives() async {
    final plannedMeal = activeMeal.value;
    if (plannedMeal == null) return;
    final requestVersion = ++_requestVersion;
    final reason = selectedReason.value;

    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      final response = await apiService.fetchSlotAlternatives(
        plannedMeal.order,
        reason: reason.value,
        excludeNames: [plannedMeal.meal.name],
        preferPantry: dashboardStore.pantry.isNotEmpty,
      );
      if (requestVersion != _requestVersion) return;
      runInAction(() {
        alternatives
          ..clear()
          ..addAll(response.alternatives);
      });
    } on ApiException catch (error) {
      if (requestVersion != _requestVersion) return;
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      if (requestVersion != _requestVersion) return;
      runInAction(
        () => errorMessage.value = 'Could not find alternatives right now.',
      );
    } finally {
      if (requestVersion == _requestVersion) {
        runInAction(() => isLoading.value = false);
      }
    }
  }

  void selectMeal(Meal meal) {
    runInAction(() {
      selectedMeal.value = meal;
      errorMessage.value = null;
    });
  }

  void clearSelection() {
    runInAction(() => selectedMeal.value = null);
  }

  Future<SlotReplacementResponse?> applySelection({
    required bool rebalanceRemaining,
  }) async {
    final plannedMeal = activeMeal.value;
    final replacement = selectedMeal.value;
    if (plannedMeal == null || replacement == null || isApplying.value) {
      return null;
    }

    runInAction(() {
      isApplying.value = true;
      errorMessage.value = null;
    });
    try {
      final response = await apiService.replacePlanSlot(
        plannedMeal.order,
        expectedCurrentName: plannedMeal.meal.name,
        replacement: replacement,
        rebalanceRemaining: rebalanceRemaining,
      );
      dashboardStore.applyPlan(response.updatedPlan);
      return response;
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
      return null;
    } catch (_) {
      runInAction(
        () => errorMessage.value = 'Could not update your plan. Try again.',
      );
      return null;
    } finally {
      runInAction(() => isApplying.value = false);
    }
  }

  void reset() {
    _requestVersion++;
    runInAction(() {
      activeMeal.value = null;
      alternatives.clear();
      selectedReason.value = MealSwapReason.surpriseMe;
      selectedMeal.value = null;
      isLoading.value = false;
      isApplying.value = false;
      errorMessage.value = null;
    });
  }
}
