// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DashboardStore on _DashboardStore, Store {
  Computed<double>? _$caloriesProgressComputed;

  @override
  double get caloriesProgress =>
      (_$caloriesProgressComputed ??= Computed<double>(
        () => super.caloriesProgress,
        name: '_DashboardStore.caloriesProgress',
      )).value;
  Computed<double>? _$proteinProgressComputed;

  @override
  double get proteinProgress => (_$proteinProgressComputed ??= Computed<double>(
    () => super.proteinProgress,
    name: '_DashboardStore.proteinProgress',
  )).value;
  Computed<double>? _$carbsProgressComputed;

  @override
  double get carbsProgress => (_$carbsProgressComputed ??= Computed<double>(
    () => super.carbsProgress,
    name: '_DashboardStore.carbsProgress',
  )).value;
  Computed<double>? _$fatsProgressComputed;

  @override
  double get fatsProgress => (_$fatsProgressComputed ??= Computed<double>(
    () => super.fatsProgress,
    name: '_DashboardStore.fatsProgress',
  )).value;
  Computed<int>? _$caloriesLeftComputed;

  @override
  int get caloriesLeft => (_$caloriesLeftComputed ??= Computed<int>(
    () => super.caloriesLeft,
    name: '_DashboardStore.caloriesLeft',
  )).value;
  Computed<int>? _$proteinLeftComputed;

  @override
  int get proteinLeft => (_$proteinLeftComputed ??= Computed<int>(
    () => super.proteinLeft,
    name: '_DashboardStore.proteinLeft',
  )).value;
  Computed<String?>? _$aiSuggestionTitleComputed;

  @override
  String? get aiSuggestionTitle =>
      (_$aiSuggestionTitleComputed ??= Computed<String?>(
        () => super.aiSuggestionTitle,
        name: '_DashboardStore.aiSuggestionTitle',
      )).value;
  Computed<String?>? _$aiSuggestionMessageComputed;

  @override
  String? get aiSuggestionMessage =>
      (_$aiSuggestionMessageComputed ??= Computed<String?>(
        () => super.aiSuggestionMessage,
        name: '_DashboardStore.aiSuggestionMessage',
      )).value;

  late final _$consumedCaloriesAtom = Atom(
    name: '_DashboardStore.consumedCalories',
    context: context,
  );

  @override
  int get consumedCalories {
    _$consumedCaloriesAtom.reportRead();
    return super.consumedCalories;
  }

  @override
  set consumedCalories(int value) {
    _$consumedCaloriesAtom.reportWrite(value, super.consumedCalories, () {
      super.consumedCalories = value;
    });
  }

  late final _$consumedProteinAtom = Atom(
    name: '_DashboardStore.consumedProtein',
    context: context,
  );

  @override
  int get consumedProtein {
    _$consumedProteinAtom.reportRead();
    return super.consumedProtein;
  }

  @override
  set consumedProtein(int value) {
    _$consumedProteinAtom.reportWrite(value, super.consumedProtein, () {
      super.consumedProtein = value;
    });
  }

  late final _$consumedCarbsAtom = Atom(
    name: '_DashboardStore.consumedCarbs',
    context: context,
  );

  @override
  int get consumedCarbs {
    _$consumedCarbsAtom.reportRead();
    return super.consumedCarbs;
  }

  @override
  set consumedCarbs(int value) {
    _$consumedCarbsAtom.reportWrite(value, super.consumedCarbs, () {
      super.consumedCarbs = value;
    });
  }

  late final _$consumedFatsAtom = Atom(
    name: '_DashboardStore.consumedFats',
    context: context,
  );

  @override
  int get consumedFats {
    _$consumedFatsAtom.reportRead();
    return super.consumedFats;
  }

  @override
  set consumedFats(int value) {
    _$consumedFatsAtom.reportWrite(value, super.consumedFats, () {
      super.consumedFats = value;
    });
  }

  late final _$targetCaloriesAtom = Atom(
    name: '_DashboardStore.targetCalories',
    context: context,
  );

  @override
  int get targetCalories {
    _$targetCaloriesAtom.reportRead();
    return super.targetCalories;
  }

  @override
  set targetCalories(int value) {
    _$targetCaloriesAtom.reportWrite(value, super.targetCalories, () {
      super.targetCalories = value;
    });
  }

  late final _$targetProteinAtom = Atom(
    name: '_DashboardStore.targetProtein',
    context: context,
  );

  @override
  int get targetProtein {
    _$targetProteinAtom.reportRead();
    return super.targetProtein;
  }

  @override
  set targetProtein(int value) {
    _$targetProteinAtom.reportWrite(value, super.targetProtein, () {
      super.targetProtein = value;
    });
  }

  late final _$targetCarbsAtom = Atom(
    name: '_DashboardStore.targetCarbs',
    context: context,
  );

  @override
  int get targetCarbs {
    _$targetCarbsAtom.reportRead();
    return super.targetCarbs;
  }

  @override
  set targetCarbs(int value) {
    _$targetCarbsAtom.reportWrite(value, super.targetCarbs, () {
      super.targetCarbs = value;
    });
  }

  late final _$targetFatsAtom = Atom(
    name: '_DashboardStore.targetFats',
    context: context,
  );

  @override
  int get targetFats {
    _$targetFatsAtom.reportRead();
    return super.targetFats;
  }

  @override
  set targetFats(int value) {
    _$targetFatsAtom.reportWrite(value, super.targetFats, () {
      super.targetFats = value;
    });
  }

  late final _$todayMealsAtom = Atom(
    name: '_DashboardStore.todayMeals',
    context: context,
  );

  @override
  ObservableList<Meal> get todayMeals {
    _$todayMealsAtom.reportRead();
    return super.todayMeals;
  }

  @override
  set todayMeals(ObservableList<Meal> value) {
    _$todayMealsAtom.reportWrite(value, super.todayMeals, () {
      super.todayMeals = value;
    });
  }

  late final _$aiCardTextAtom = Atom(
    name: '_DashboardStore.aiCardText',
    context: context,
  );

  @override
  String get aiCardText {
    _$aiCardTextAtom.reportRead();
    return super.aiCardText;
  }

  @override
  set aiCardText(String value) {
    _$aiCardTextAtom.reportWrite(value, super.aiCardText, () {
      super.aiCardText = value;
    });
  }

  late final _$aiCardStateAtom = Atom(
    name: '_DashboardStore.aiCardState',
    context: context,
  );

  @override
  AICardState get aiCardState {
    _$aiCardStateAtom.reportRead();
    return super.aiCardState;
  }

  @override
  set aiCardState(AICardState value) {
    _$aiCardStateAtom.reportWrite(value, super.aiCardState, () {
      super.aiCardState = value;
    });
  }

  late final _$showAiSuggestionAtom = Atom(
    name: '_DashboardStore.showAiSuggestion',
    context: context,
  );

  @override
  bool get showAiSuggestion {
    _$showAiSuggestionAtom.reportRead();
    return super.showAiSuggestion;
  }

  @override
  set showAiSuggestion(bool value) {
    _$showAiSuggestionAtom.reportWrite(value, super.showAiSuggestion, () {
      super.showAiSuggestion = value;
    });
  }

  late final _$dayStatusAtom = Atom(
    name: '_DashboardStore.dayStatus',
    context: context,
  );

  @override
  DayStatus get dayStatus {
    _$dayStatusAtom.reportRead();
    return super.dayStatus;
  }

  @override
  set dayStatus(DayStatus value) {
    _$dayStatusAtom.reportWrite(value, super.dayStatus, () {
      super.dayStatus = value;
    });
  }

  late final _$nextMealAtom = Atom(
    name: '_DashboardStore.nextMeal',
    context: context,
  );

  @override
  NextMealRecommendation? get nextMeal {
    _$nextMealAtom.reportRead();
    return super.nextMeal;
  }

  @override
  set nextMeal(NextMealRecommendation? value) {
    _$nextMealAtom.reportWrite(value, super.nextMeal, () {
      super.nextMeal = value;
    });
  }

  late final _$recalibrationAtom = Atom(
    name: '_DashboardStore.recalibration',
    context: context,
  );

  @override
  RecalibrationStatus? get recalibration {
    _$recalibrationAtom.reportRead();
    return super.recalibration;
  }

  @override
  set recalibration(RecalibrationStatus? value) {
    _$recalibrationAtom.reportWrite(value, super.recalibration, () {
      super.recalibration = value;
    });
  }

  late final _$flexPlanAtom = Atom(
    name: '_DashboardStore.flexPlan',
    context: context,
  );

  @override
  ObservableList<FlexPlanSlot> get flexPlan {
    _$flexPlanAtom.reportRead();
    return super.flexPlan;
  }

  @override
  set flexPlan(ObservableList<FlexPlanSlot> value) {
    _$flexPlanAtom.reportWrite(value, super.flexPlan, () {
      super.flexPlan = value;
    });
  }

  late final _$pantryAtom = Atom(
    name: '_DashboardStore.pantry',
    context: context,
  );

  @override
  ObservableList<PantryItem> get pantry {
    _$pantryAtom.reportRead();
    return super.pantry;
  }

  @override
  set pantry(ObservableList<PantryItem> value) {
    _$pantryAtom.reportWrite(value, super.pantry, () {
      super.pantry = value;
    });
  }

  late final _$isLoadingPantryAtom = Atom(
    name: '_DashboardStore.isLoadingPantry',
    context: context,
  );

  @override
  bool get isLoadingPantry {
    _$isLoadingPantryAtom.reportRead();
    return super.isLoadingPantry;
  }

  @override
  set isLoadingPantry(bool value) {
    _$isLoadingPantryAtom.reportWrite(value, super.isLoadingPantry, () {
      super.isLoadingPantry = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_DashboardStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$hasErrorAtom = Atom(
    name: '_DashboardStore.hasError',
    context: context,
  );

  @override
  bool get hasError {
    _$hasErrorAtom.reportRead();
    return super.hasError;
  }

  @override
  set hasError(bool value) {
    _$hasErrorAtom.reportWrite(value, super.hasError, () {
      super.hasError = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_DashboardStore.errorMessage',
    context: context,
  );

  @override
  String get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$refreshAsyncAction = AsyncAction(
    '_DashboardStore.refresh',
    context: context,
  );

  @override
  Future<void> refresh() {
    return _$refreshAsyncAction.run(() => super.refresh());
  }

  late final _$addMealAsyncAction = AsyncAction(
    '_DashboardStore.addMeal',
    context: context,
  );

  @override
  Future<void> addMeal(Meal meal) {
    return _$addMealAsyncAction.run(() => super.addMeal(meal));
  }

  late final _$acceptNextMealAsyncAction = AsyncAction(
    '_DashboardStore.acceptNextMeal',
    context: context,
  );

  @override
  Future<void> acceptNextMeal() {
    return _$acceptNextMealAsyncAction.run(() => super.acceptNextMeal());
  }

  late final _$swapNextMealAsyncAction = AsyncAction(
    '_DashboardStore.swapNextMeal',
    context: context,
  );

  @override
  Future<void> swapNextMeal() {
    return _$swapNextMealAsyncAction.run(() => super.swapNextMeal());
  }

  late final _$fetchHistoryAsyncAction = AsyncAction(
    '_DashboardStore.fetchHistory',
    context: context,
  );

  @override
  Future<List<DayHistoryEntry>> fetchHistory({int days = 7}) {
    return _$fetchHistoryAsyncAction.run(() => super.fetchHistory(days: days));
  }

  late final _$quickActionAsyncAction = AsyncAction(
    '_DashboardStore.quickAction',
    context: context,
  );

  @override
  Future<void> quickAction(String action) {
    return _$quickActionAsyncAction.run(() => super.quickAction(action));
  }

  late final _$loadPantryAsyncAction = AsyncAction(
    '_DashboardStore.loadPantry',
    context: context,
  );

  @override
  Future<void> loadPantry() {
    return _$loadPantryAsyncAction.run(() => super.loadPantry());
  }

  late final _$_DashboardStoreActionController = ActionController(
    name: '_DashboardStore',
    context: context,
  );

  @override
  void applyPlan(DailyPlan plan) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
      name: '_DashboardStore.applyPlan',
    );
    try {
      return super.applyPlan(plan);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
      name: '_DashboardStore.reset',
    );
    try {
      return super.reset();
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
consumedCalories: ${consumedCalories},
consumedProtein: ${consumedProtein},
consumedCarbs: ${consumedCarbs},
consumedFats: ${consumedFats},
targetCalories: ${targetCalories},
targetProtein: ${targetProtein},
targetCarbs: ${targetCarbs},
targetFats: ${targetFats},
todayMeals: ${todayMeals},
aiCardText: ${aiCardText},
aiCardState: ${aiCardState},
showAiSuggestion: ${showAiSuggestion},
dayStatus: ${dayStatus},
nextMeal: ${nextMeal},
recalibration: ${recalibration},
flexPlan: ${flexPlan},
pantry: ${pantry},
isLoadingPantry: ${isLoadingPantry},
isLoading: ${isLoading},
hasError: ${hasError},
errorMessage: ${errorMessage},
caloriesProgress: ${caloriesProgress},
proteinProgress: ${proteinProgress},
carbsProgress: ${carbsProgress},
fatsProgress: ${fatsProgress},
caloriesLeft: ${caloriesLeft},
proteinLeft: ${proteinLeft},
aiSuggestionTitle: ${aiSuggestionTitle},
aiSuggestionMessage: ${aiSuggestionMessage}
    ''';
  }
}
