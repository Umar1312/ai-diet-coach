import 'package:mobx/mobx.dart';
import '../core/di/providers.dart';
import '../shared/models/dashboard_state.dart';
import '../shared/models/meal.dart';

part 'dashboard_store.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  @observable
  int consumedCalories = 0;

  @observable
  int consumedProtein = 0;

  @observable
  int consumedCarbs = 0;

  @observable
  int consumedFats = 0;

  @observable
  int targetCalories = 2000;

  @observable
  int targetProtein = 200;

  @observable
  int targetCarbs = 175;

  @observable
  int targetFats = 56;

  @observable
  ObservableList<Meal> todayMeals = ObservableList<Meal>();

  @observable
  String aiCardText = '';

  @observable
  AICardState aiCardState = AICardState.onTrack;

  @observable
  bool isLoading = false;

  @observable
  bool hasError = false;

  @observable
  String errorMessage = '';

  @observable
  bool showAiSuggestion = false;

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

  @action
  Future<void> fetchDashboard() async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    try {
      final state = await apiService.fetchDashboard();
      setDashboardState(state);
    } on ApiException catch (e) {
      hasError = true;
      errorMessage = e.message;
    } catch (e) {
      hasError = true;
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
    }
  }

  @action
  void addMeal(Meal meal) {
    todayMeals.add(meal);
    consumedCalories += meal.calories;
    consumedProtein += meal.protein;
    consumedCarbs += meal.carbs;
    consumedFats += meal.fats;
    showAiSuggestion = true;
    aiCardState = AICardState.behindProtein;
    aiCardText =
        "You're behind on protein. A high-protein dinner will fix today.";
  }

  @action
  void setDashboardState(DashboardState state) {
    consumedCalories = state.consumedCalories;
    consumedProtein = state.consumedProtein;
    consumedCarbs = state.consumedCarbs;
    consumedFats = state.consumedFats;
    targetCalories = state.targetCalories;
    targetProtein = state.targetProtein;
    targetCarbs = state.targetCarbs;
    targetFats = state.targetFats;
    aiCardText = state.aiCardText;
    aiCardState = state.aiCardState;
    todayMeals = ObservableList<Meal>.of(state.meals);
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
  }
}
