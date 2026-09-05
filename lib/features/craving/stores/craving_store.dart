import 'package:mobx/mobx.dart';
import '../../../core/di/providers.dart';
import '../../../shared/models/home_models.dart';
import '../../../shared/models/meal.dart';
import '../../../shared/models/meal_log_response.dart';
import '../../../stores/dashboard_store.dart';

enum CravingPhase { prompt, thinking, reveal, error }

class CravingStore {
  final DashboardStore dashboardStore;

  CravingStore({required this.dashboardStore});

  // ── Observables ─────────────────────────────────────────────────────────

  final cravingText = Observable<String>('');
  final selectedTags = ObservableList<String>();
  final phase = Observable<CravingPhase>(CravingPhase.prompt);
  final result = Observable<NextMealRecommendation?>(null);
  final errorMessage = Observable<String?>('');
  final isLogging = Observable<bool>(false);

  // ── Computed ────────────────────────────────────────────────────────────

  late final canSubmit = Computed<bool>(
    () =>
        cravingText.value.trim().length >= 2 &&
        phase.value != CravingPhase.thinking,
  );

  // ── Actions ─────────────────────────────────────────────────────────────

  void setText(String value) {
    runInAction(() => cravingText.value = value);
  }

  void toggleTag(String tag) {
    runInAction(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else if (selectedTags.length < 5) {
        selectedTags.add(tag);
      }
    });
  }

  void clearError() {
    runInAction(() => errorMessage.value = '');
  }

  void reset() {
    runInAction(() {
      cravingText.value = '';
      selectedTags.clear();
      phase.value = CravingPhase.prompt;
      result.value = null;
      errorMessage.value = '';
      isLogging.value = false;
    });
  }

  Future<void> requestCraving({bool preferPantry = false}) async {
    runInAction(() {
      phase.value = CravingPhase.thinking;
      errorMessage.value = '';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final response = await apiService.requestCraving(
        cravingText.value.trim(),
        tags: selectedTags.toList(),
        preferPantry: preferPantry,
      );

      // Enforce minimum thinking duration for UX (1500ms)
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsed));
      }

      runInAction(() {
        result.value = response.nextMeal;
        phase.value = CravingPhase.reveal;
      });
    } on ApiException catch (e) {
      runInAction(() {
        errorMessage.value = e.message;
        phase.value = CravingPhase.error;
      });
    } catch (_) {
      runInAction(() {
        errorMessage.value = "Couldn't think of anything. Try again.";
        phase.value = CravingPhase.error;
      });
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> tryAgain({bool preferPantry = false}) async {
    runInAction(() {
      phase.value = CravingPhase.thinking;
      errorMessage.value = '';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final response = await apiService.requestCraving(
        cravingText.value.trim(),
        tags: selectedTags.toList(),
        preferPantry: preferPantry,
      );

      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 1200) {
        await Future.delayed(Duration(milliseconds: 1200 - elapsed));
      }

      runInAction(() {
        result.value = response.nextMeal;
        phase.value = CravingPhase.reveal;
      });
    } on ApiException catch (e) {
      runInAction(() {
        errorMessage.value = e.message;
        phase.value = CravingPhase.error;
      });
    } catch (_) {
      runInAction(() {
        errorMessage.value = "Couldn't think of anything. Try again.";
        phase.value = CravingPhase.error;
      });
    } finally {
      stopwatch.stop();
    }
  }

  Future<MealLogResponse?> logChosen() async {
    final meal = result.value;
    if (meal == null) return null;

    runInAction(() => isLogging.value = true);
    try {
      return await dashboardStore.addMeal(
        Meal(
          name: meal.name,
          emoji: meal.emoji,
          prepMinutes: meal.prepMinutes,
          calories: meal.calories,
          proteinG: meal.proteinG,
          carbsG: meal.carbsG,
          fatsG: meal.fatsG,
          nutritionBasis: NutritionBasis(
            servingAmount: 1,
            servingUnit: 'serving',
            calories: meal.calories,
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatsG: meal.fatsG,
          ),
        ),
        source: 'recommendation',
        intent: MealLogIntent.extra,
      );
    } finally {
      runInAction(() => isLogging.value = false);
    }
  }
}
