import 'package:mobx/mobx.dart';
import '../../core/di/providers.dart';
import '../../shared/models/dashboard_state.dart';
import '../../shared/models/history_response.dart';
import '../../shared/models/home_models.dart';
import '../../shared/models/meal.dart';
import '../../shared/models/meal_log_response.dart';

part 'dashboard_store.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  _DashboardStore() {
    refresh();
  }

  // ── Core daily numbers ──────────────────────────────────────────────────

  @observable
  int consumedCalories = 0;

  @observable
  int consumedProtein = 0;

  @observable
  int consumedCarbs = 0;

  @observable
  int consumedFats = 0;

  @observable
  int targetCalories = 2191;

  @observable
  int targetProtein = 170;

  @observable
  int targetCarbs = 240;

  @observable
  int targetFats = 60;

  @observable
  ObservableList<Meal> todayMeals = ObservableList<Meal>();

  // ── Legacy AI coach fields (kept for back-compat with other screens) ────

  @observable
  String aiCardText = '';

  @observable
  AICardState aiCardState = AICardState.onTrack;

  @observable
  bool showAiSuggestion = false;

  // ── New autopilot home state ────────────────────────────────────────────

  @observable
  DayStatus dayStatus = DayStatus.onTrack;

  @observable
  NextMealRecommendation? nextMeal;

  @observable
  RecalibrationStatus? recalibration;

  @observable
  ObservableList<FlexPlanSlot> flexPlan = ObservableList<FlexPlanSlot>();

  @observable
  ObservableList<PantryItem> pantry = ObservableList<PantryItem>();

  @observable
  bool isLoadingPantry = false;

  // ── Loading / error flags (kept so shimmer still works if needed) ───────

  @observable
  bool isLoading = false;

  @observable
  bool hasError = false;

  @observable
  String errorMessage = '';

  // ── Computed ────────────────────────────────────────────────────────────

  @computed
  double get caloriesProgress =>
      targetCalories > 0 ? consumedCalories / targetCalories : 0.0;

  @computed
  double get proteinProgress =>
      targetProtein > 0 ? consumedProtein / targetProtein : 0.0;

  @computed
  double get carbsProgress =>
      targetCarbs > 0 ? consumedCarbs / targetCarbs : 0.0;

  @computed
  double get fatsProgress => targetFats > 0 ? consumedFats / targetFats : 0.0;

  @computed
  int get caloriesLeft => targetCalories - consumedCalories;

  @computed
  int get proteinLeft => targetProtein - consumedProtein;

  @computed
  String? get aiSuggestionTitle {
    switch (aiCardState) {
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
  }

  @computed
  String? get aiSuggestionMessage => aiCardText.isEmpty ? null : aiCardText;

  // ── Actions ─────────────────────────────────────────────────────────────

  @action
  void applyPlan(DailyPlan plan) {
    consumedCalories = plan.consumed.calories;
    consumedProtein = plan.consumed.proteinG;
    consumedCarbs = plan.consumed.carbsG;
    consumedFats = plan.consumed.fatsG;
    targetCalories = plan.targets.calories;
    targetProtein = plan.targets.proteinG;
    targetCarbs = plan.targets.carbsG;
    targetFats = plan.targets.fatsG;
    todayMeals = ObservableList.of(plan.meals);
    aiCardText = plan.aiCardText;
    aiCardState = plan.aiCardState;
    dayStatus = plan.dayStatus;
    nextMeal = plan.nextMeal;
    recalibration = plan.recalibration;
    flexPlan = ObservableList.of(plan.flexPlan);
  }

  @action
  Future<void> refresh() async {
    isLoading = true;
    hasError = false;
    try {
      final plan = await apiService.fetchDashboard();
      applyPlan(plan);
    } catch (e) {
      hasError = true;
      errorMessage = e is ApiException ? e.message : 'Failed to load dashboard';
    } finally {
      isLoading = false;
    }
  }

  @action
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

  @action
  Future<void> acceptNextMeal() async {
    final meal = nextMeal;
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

  @action
  Future<void> swapNextMeal() async {
    final current = nextMeal?.name ?? '';
    final response = await apiService.swapMeal(current);
    nextMeal = response.nextMeal;
  }

  @action
  Future<List<DayHistoryEntry>> fetchHistory({int days = 7}) async {
    final response = await apiService.fetchHistory(days: days);
    return response.days;
  }

  @action
  Future<void> quickAction(String action) async {
    final response = await apiService.quickAction(action);
    nextMeal = response.nextMeal;
  }

  @action
  Future<void> loadPantry() async {
    isLoadingPantry = true;
    try {
      final response = await apiService.fetchPantry();
      pantry = ObservableList.of(
        response.items.map(PantryItem.fromResponse).toList(),
      );
    } catch (e) {
      // Silently fail — pantry is optional
    } finally {
      isLoadingPantry = false;
    }
  }

  @action
  void reset() {
    consumedCalories = 0;
    consumedProtein = 0;
    consumedCarbs = 0;
    consumedFats = 0;
    todayMeals = ObservableList<Meal>();
    aiCardText = '';
    aiCardState = AICardState.onTrack;
    showAiSuggestion = false;
    dayStatus = DayStatus.onTrack;
    nextMeal = null;
    recalibration = null;
    flexPlan = ObservableList<FlexPlanSlot>();
    pantry = ObservableList<PantryItem>();
  }
}
