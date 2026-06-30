import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/features/customize_day/models/custom_day_plan_request.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';

const _slots = ['breakfast', 'lunch', 'dinner', 'snack', 'late'];

class CustomizeDayStore {
  // ── Observables ─────────────────────────────────────────────────────────

  final meals = ObservableList<ObservableList<Meal>>();
  final isSaving = Observable<bool>(false);
  final errorMessage = Observable<String?>('');

  // ── Computed ────────────────────────────────────────────────────────────

  late final totalCalories = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.calories),
  );

  late final totalProtein = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.proteinG),
  );

  late final totalCarbs = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.carbsG),
  );

  late final totalFats = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.fatsG),
  );

  late final caloriesProgress = Computed<double>(
    () => dashboardStore.targetCalories.value > 0
        ? (totalCalories.value / dashboardStore.targetCalories.value).clamp(
            0.0,
            1.0,
          )
        : 0.0,
  );

  late final proteinProgress = Computed<double>(
    () => dashboardStore.targetProtein.value > 0
        ? (totalProtein.value / dashboardStore.targetProtein.value).clamp(
            0.0,
            1.0,
          )
        : 0.0,
  );

  late final carbsProgress = Computed<double>(
    () => dashboardStore.targetCarbs.value > 0
        ? (totalCarbs.value / dashboardStore.targetCarbs.value).clamp(0.0, 1.0)
        : 0.0,
  );

  late final fatsProgress = Computed<double>(
    () => dashboardStore.targetFats.value > 0
        ? (totalFats.value / dashboardStore.targetFats.value).clamp(0.0, 1.0)
        : 0.0,
  );

  late final canSave = Computed<bool>(
    () => meals.any((slotMeals) => slotMeals.isNotEmpty) && !isSaving.value,
  );

  // ── Actions ─────────────────────────────────────────────────────────────

  CustomizeDayStore() {
    // Start with 5 blank slots.
    runInAction(() {
      meals.addAll(List.generate(5, (_) => ObservableList<Meal>()));
    });
  }

  void addMeal(int order, Meal meal) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        meals[order].add(meal);
      }
    });
  }

  void setMealFromPantry(int order, PantrySuggestionItem item) {
    addMeal(
      order,
      Meal(
        name: item.name,
        emoji: item.emoji,
        calories: item.calories,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatsG: item.fatsG,
      ),
    );
  }

  void removeMeal(int order, int mealIndex) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        final slotMeals = meals[order];
        if (mealIndex >= 0 && mealIndex < slotMeals.length) {
          slotMeals.removeAt(mealIndex);
        }
      }
    });
  }

  void clearSlot(int order) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        meals[order].clear();
      }
    });
  }

  void reset() {
    runInAction(() {
      for (var i = 0; i < meals.length; i++) {
        meals[i].clear();
      }
      errorMessage.value = '';
    });
  }

  Future<void> save() async {
    final filledMeals = <int, Meal>{};
    for (var i = 0; i < meals.length; i++) {
      final slotMeals = meals[i];
      if (slotMeals.isNotEmpty) {
        filledMeals[i] = _combineSlotMeals(slotMeals);
      }
    }

    if (filledMeals.isEmpty) return;

    runInAction(() {
      isSaving.value = true;
      errorMessage.value = '';
    });

    try {
      final request = CustomDayPlanRequest(
        meals: filledMeals.entries.map((e) {
          final order = e.key;
          final meal = e.value;
          return CustomPlannedMeal(
            slot: _slots[order],
            order: order,
            name: meal.name,
            emoji: meal.emoji,
            calories: meal.calories,
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatsG: meal.fatsG,
          );
        }).toList(),
      );

      final plan = await apiService.saveCustomDayPlan(request);
      runInAction(() => errorMessage.value = '');
      dashboardStore.applyPlan(plan);
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(() => errorMessage.value = 'Failed to save custom plan.');
    } finally {
      runInAction(() => isSaving.value = false);
    }
  }

  Meal _combineSlotMeals(List<Meal> slotMeals) {
    final names = slotMeals.map((meal) => meal.name).toList();
    final joinedName = names.join(' + ');
    return Meal(
      name: joinedName.length <= 200
          ? joinedName
          : '${joinedName.substring(0, 197)}...',
      emoji: slotMeals.length == 1 ? slotMeals.first.emoji : '🍽️',
      calories: slotMeals.fold(0, (sum, meal) => sum + meal.calories),
      proteinG: slotMeals.fold(0, (sum, meal) => sum + meal.proteinG),
      carbsG: slotMeals.fold(0, (sum, meal) => sum + meal.carbsG),
      fatsG: slotMeals.fold(0, (sum, meal) => sum + meal.fatsG),
    );
  }
}
