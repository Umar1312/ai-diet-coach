import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';
import 'package:diet_coach_ai/stores/notification_store.dart';

class MealCheckInStore {
  final DashboardStore dashboardStore;
  final NotificationStore notificationStore;

  MealCheckInStore({
    required this.dashboardStore,
    required this.notificationStore,
  });

  final slot = Observable<String>('');
  final isLoading = Observable<bool>(false);
  final isSubmitting = Observable<bool>(false);
  final errorMessage = Observable<String>('');

  PlannedMeal? get plannedMeal {
    for (final meal in dashboardStore.plannedMeals) {
      if (meal.slot == slot.value) return meal;
    }
    return null;
  }

  Future<void> prepare(String value) async {
    runInAction(() {
      slot.value = value;
      isLoading.value = true;
      errorMessage.value = '';
    });
    await dashboardStore.refresh();
    runInAction(() {
      isLoading.value = false;
      if (plannedMeal == null) {
        errorMessage.value = dashboardStore.hasError.value
            ? dashboardStore.errorMessage.value
            : 'This meal is no longer in today\'s plan.';
      }
    });
  }

  Future<bool> confirmPlannedMeal() async {
    final meal = plannedMeal;
    if (meal == null || isSubmitting.value) return false;
    runInAction(() {
      isSubmitting.value = true;
      errorMessage.value = '';
    });
    try {
      await dashboardStore.addMeal(
        meal.meal,
        source: 'notification',
        intent: MealLogIntent.planned,
        slotId: meal.id,
      );
      return true;
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Failed to log this meal.');
    } finally {
      runInAction(() => isSubmitting.value = false);
    }
    return false;
  }

  Future<bool> skipPlannedMeal() async {
    final meal = plannedMeal;
    if (meal == null || isSubmitting.value) return false;
    runInAction(() {
      isSubmitting.value = true;
      errorMessage.value = '';
    });
    try {
      await dashboardStore.skipSlot(meal.id);
      final updated = plannedMeal;
      if (updated?.status != PlannedMealStatus.skipped) {
        runInAction(() {
          errorMessage.value = dashboardStore.errorMessage.value.isEmpty
              ? 'Failed to skip this meal.'
              : dashboardStore.errorMessage.value;
        });
        return false;
      }
      return true;
    } finally {
      runInAction(() => isSubmitting.value = false);
    }
  }

  Future<void> snooze() => notificationStore.snooze(slot.value);
}
