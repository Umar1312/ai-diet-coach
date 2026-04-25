import 'package:mobx/mobx.dart';
import '../../core/di/providers.dart';
import '../../shared/models/dashboard_state.dart';
import '../../shared/models/history_response.dart';
import '../../shared/models/home_models.dart';
import '../../shared/models/meal.dart';
import '../../shared/models/meal_log_response.dart';

/// MobX store WITHOUT codegen.
/// All observables/computed are declared manually via Observable()/Computed().
class DashboardStore {
  DashboardStore() {
    refresh();
  }

  // ── Core daily numbers ──────────────────────────────────────────────────

  final consumedCalories = Observable<int>(0);
  final consumedProtein = Observable<int>(0);
  final consumedCarbs = Observable<int>(0);
  final consumedFats = Observable<int>(0);

  final targetCalories = Observable<int>(2191);
  final targetProtein = Observable<int>(170);
  final targetCarbs = Observable<int>(240);
  final targetFats = Observable<int>(60);

  final todayMeals = ObservableList<Meal>();

  // ── Legacy AI coach fields ──────────────────────────────────────────────

  final aiCardText = Observable<String>('');
  final aiCardState = Observable<AICardState>(AICardState.onTrack);
  final showAiSuggestion = Observable<bool>(false);

  // ── Autopilot home state ────────────────────────────────────────────────

  final dayStatus = Observable<DayStatus>(DayStatus.onTrack);
  final nextMeal = Observable<NextMealRecommendation?>(null);
  final recalibration = Observable<RecalibrationStatus?>(null);
  final flexPlan = ObservableList<FlexPlanSlot>();
  final pantry = ObservableList<PantryItem>();

  final isLoadingPantry = Observable<bool>(false);
  final isLoading = Observable<bool>(false);
  final hasError = Observable<bool>(false);
  final errorMessage = Observable<String>('');

  // ── Computed ────────────────────────────────────────────────────────────

  late final caloriesProgress = Computed<double>(
    () => targetCalories.value > 0
        ? consumedCalories.value / targetCalories.value
        : 0.0,
  );

  late final proteinProgress = Computed<double>(
    () => targetProtein.value > 0
        ? consumedProtein.value / targetProtein.value
        : 0.0,
  );

  late final carbsProgress = Computed<double>(
    () => targetCarbs.value > 0 ? consumedCarbs.value / targetCarbs.value : 0.0,
  );

  late final fatsProgress = Computed<double>(
    () => targetFats.value > 0 ? consumedFats.value / targetFats.value : 0.0,
  );

  late final caloriesLeft = Computed<int>(
    () => targetCalories.value - consumedCalories.value,
  );

  late final proteinLeft = Computed<int>(
    () => targetProtein.value - consumedProtein.value,
  );

  late final aiSuggestionTitle = Computed<String?>(() {
    switch (aiCardState.value) {
      case AICardState.onTrack:
        return 'On Track';
      case AICardState.skippedMeal:
        return 'Skipped Meal';
      case AICardState.behindProtein:
        return 'Behind on Protein';
      case AICardState.calorieLimit:
        return 'Calorie Limit';
      case AICardState.goalHit:
        return 'Goal Hit!';
    }
  });

  late final aiSuggestionMessage = Computed<String?>(
    () => aiCardText.value.isEmpty ? null : aiCardText.value,
  );

  // ── Actions ─────────────────────────────────────────────────────────────

  void applyPlan(DailyPlan plan) {
    runInAction(() {
      consumedCalories.value = plan.consumed.calories;
      consumedProtein.value = plan.consumed.proteinG;
      consumedCarbs.value = plan.consumed.carbsG;
      consumedFats.value = plan.consumed.fatsG;
      targetCalories.value = plan.targets.calories;
      targetProtein.value = plan.targets.proteinG;
      targetCarbs.value = plan.targets.carbsG;
      targetFats.value = plan.targets.fatsG;
      todayMeals
        ..clear()
        ..addAll(plan.meals);
      aiCardText.value = plan.aiCardText;
      aiCardState.value = plan.aiCardState;
      dayStatus.value = plan.dayStatus;
      nextMeal.value = plan.nextMeal;
      recalibration.value = plan.recalibration;
      flexPlan
        ..clear()
        ..addAll(plan.flexPlan);
    });
  }

  Future<void> refresh() async {
    runInAction(() {
      isLoading.value = true;
      hasError.value = false;
    });
    try {
      final plan = await apiService.fetchDashboard();
      applyPlan(plan);
    } catch (e) {
      runInAction(() {
        hasError.value = true;
        errorMessage.value = e is ApiException
            ? e.message
            : 'Failed to load dashboard';
      });
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  Future<void> addMeal(Meal meal) async {
    final response = await apiService.logManual(
      ManualLogRequest(
        foodName: meal.foodName,
        calories: meal.calories,
        proteinG: meal.proteinG,
        carbsG: meal.carbsG,
        fatsG: meal.fatsG,
        source: meal.source,
      ),
    );
    applyPlan(response.updatedPlan);
  }

  Future<void> acceptNextMeal() async {
    final meal = nextMeal.value;
    if (meal == null) return;
    final response = await apiService.logManual(
      ManualLogRequest(
        foodName: meal.name,
        calories: meal.calories,
        proteinG: meal.proteinG,
        carbsG: meal.carbsG,
        fatsG: meal.fatsG,
        source: 'recommendation',
      ),
    );
    applyPlan(response.updatedPlan);
  }

  Future<void> swapNextMeal() async {
    final current = nextMeal.value?.name ?? '';
    final response = await apiService.swapMeal(current);
    runInAction(() => nextMeal.value = response.nextMeal);
  }

  Future<List<DayHistoryEntry>> fetchHistory({int days = 7}) async {
    final response = await apiService.fetchHistory(days: days);
    return response.days;
  }

  Future<void> quickAction(String action) async {
    final response = await apiService.quickAction(action);
    runInAction(() => nextMeal.value = response.nextMeal);
  }

  Future<void> loadPantry() async {
    runInAction(() => isLoadingPantry.value = true);
    try {
      final response = await apiService.fetchPantry();
      runInAction(() {
        pantry
          ..clear()
          ..addAll(response.items.map(PantryItem.fromResponse).toList());
      });
    } catch (e) {
      // Silently fail
    } finally {
      runInAction(() => isLoadingPantry.value = false);
    }
  }

  void reset() {
    runInAction(() {
      consumedCalories.value = 0;
      consumedProtein.value = 0;
      consumedCarbs.value = 0;
      consumedFats.value = 0;
      todayMeals.clear();
      aiCardText.value = '';
      aiCardState.value = AICardState.onTrack;
      showAiSuggestion.value = false;
      dayStatus.value = DayStatus.onTrack;
      nextMeal.value = null;
      recalibration.value = null;
      flexPlan.clear();
      pantry.clear();
    });
  }
}
