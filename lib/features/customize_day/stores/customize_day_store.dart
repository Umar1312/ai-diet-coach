import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/features/customize_day/models/custom_day_plan_request.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';

const _slots = ['breakfast', 'lunch', 'dinner', 'snack', 'late'];
const _maxQuantity = 20;

class CustomizeDayStore {
  // ── Observables ─────────────────────────────────────────────────────────

  final meals = ObservableList<ObservableList<MealComponent>>();
  final isSaving = Observable<bool>(false);
  final errorMessage = Observable<String?>('');

  // ── Computed ────────────────────────────────────────────────────────────

  late final totalCalories = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.totalCalories),
  );

  late final totalProtein = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.totalProteinG),
  );

  late final totalCarbs = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.totalCarbsG),
  );

  late final totalFats = Computed<int>(
    () => meals
        .expand((slotMeals) => slotMeals)
        .fold(0, (sum, m) => sum + m.totalFatsG),
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
      meals.addAll(List.generate(5, (_) => ObservableList<MealComponent>()));
    });
  }

  void addFoodItem(int order, FoodItem item) {
    addComponent(order, item.toComponent());
  }

  void addComponent(int order, MealComponent component) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        final slotMeals = meals[order];
        final existingIndex = slotMeals.indexWhere(
          (item) => _sameComponent(item, component),
        );
        if (existingIndex == -1) {
          slotMeals.add(component);
          return;
        }

        final existing = slotMeals[existingIndex];
        if (existing.quantity < _maxQuantity) {
          final mergedQuantity = existing.quantity + component.quantity;
          slotMeals[existingIndex] = existing.copyWith(
            quantity: mergedQuantity > _maxQuantity
                ? _maxQuantity
                : mergedQuantity,
          );
        }
      }
    });
  }

  void incrementComponent(int order, int componentIndex) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        final slotMeals = meals[order];
        if (componentIndex >= 0 && componentIndex < slotMeals.length) {
          final component = slotMeals[componentIndex];
          if (component.quantity < _maxQuantity) {
            slotMeals[componentIndex] = component.copyWith(
              quantity: component.quantity + 1,
            );
          }
        }
      }
    });
  }

  void decrementComponent(int order, int componentIndex) {
    runInAction(() {
      if (order >= 0 && order < meals.length) {
        final slotMeals = meals[order];
        if (componentIndex >= 0 && componentIndex < slotMeals.length) {
          final component = slotMeals[componentIndex];
          if (component.quantity <= 1) {
            slotMeals.removeAt(componentIndex);
          } else {
            slotMeals[componentIndex] = component.copyWith(
              quantity: component.quantity - 1,
            );
          }
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
    final filledMeals = <int, List<MealComponent>>{};
    for (var i = 0; i < meals.length; i++) {
      final slotMeals = meals[i];
      if (slotMeals.isNotEmpty) {
        filledMeals[i] = slotMeals.toList();
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
            name: _buildSlotName(meal),
            emoji: meal.length == 1 ? meal.first.emoji : '🍽️',
            components: meal,
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

  String _buildSlotName(List<MealComponent> slotMeals) {
    final names = slotMeals
        .map(
          (meal) =>
              meal.quantity == 1 ? meal.name : '${meal.quantity}x ${meal.name}',
        )
        .toList();
    final joinedName = names.join(' + ');
    return joinedName.length <= 200
        ? joinedName
        : '${joinedName.substring(0, 197)}...';
  }

  bool _sameComponent(MealComponent a, MealComponent b) {
    if (a.foodItemId != null && b.foodItemId != null) {
      return a.foodItemId == b.foodItemId;
    }
    return a.name == b.name &&
        a.emoji == b.emoji &&
        a.servingSize == b.servingSize &&
        a.caloriesPerServing == b.caloriesPerServing &&
        a.proteinGPerServing == b.proteinGPerServing &&
        a.carbsGPerServing == b.carbsGPerServing &&
        a.fatsGPerServing == b.fatsGPerServing;
  }
}
