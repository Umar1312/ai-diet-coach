import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

class MealLoggingStore {
  static const _uuid = Uuid();
  final ApiService apiService;
  final DashboardStore dashboardStore;

  MealLoggingStore({required this.apiService, required this.dashboardStore});

  static const pageSize = 20;

  final query = Observable<String>('');
  final results = ObservableList<FoodItem>();
  final isSearching = Observable<bool>(false);
  final isLoadingMore = Observable<bool>(false);
  final hasMore = Observable<bool>(false);
  final loggingPlanOrder = Observable<int?>(null);
  final loggingFoodId = Observable<String?>(null);
  final isEstimating = Observable<bool>(false);
  final errorMessage = Observable<String?>(null);
  final pendingMealName = Observable<String?>(null);
  final pendingMealEmoji = Observable<String>('🍽️');
  final adaptationMessage = Observable<String?>(null);

  int _currentPage = 1;
  int _searchGeneration = 0;
  PlannedMeal? _retryPlannedMeal;
  FoodItem? _retryFood;
  PlannedMeal? _retryReplacedSlot;
  double _retryServings = 1;
  String? _retryEstimateQuery;
  _MealLogAttempt? _lastAttempt;
  String? _retryOperationId;

  bool get isLogging =>
      loggingPlanOrder.value != null ||
      loggingFoodId.value != null ||
      isEstimating.value;

  void setQuery(String value) {
    runInAction(() {
      query.value = value;
      errorMessage.value = null;
      if (value.trim().isEmpty) {
        results.clear();
        hasMore.value = false;
      }
    });
  }

  void clearError() => runInAction(() => errorMessage.value = null);

  void resetSearch() {
    _searchGeneration++;
    _currentPage = 1;
    runInAction(() {
      query.value = '';
      results.clear();
      isSearching.value = false;
      isLoadingMore.value = false;
      hasMore.value = false;
      errorMessage.value = null;
    });
  }

  Future<void> search() async {
    final searchQuery = query.value.trim();
    final generation = ++_searchGeneration;
    if (searchQuery.isEmpty) {
      runInAction(() {
        results.clear();
        hasMore.value = false;
        isSearching.value = false;
      });
      return;
    }

    runInAction(() {
      isSearching.value = true;
      errorMessage.value = null;
    });
    try {
      final response = await apiService.searchFoods(
        q: searchQuery,
        source: 'catalog',
        pageSize: pageSize,
      );
      if (generation != _searchGeneration ||
          searchQuery != query.value.trim()) {
        return;
      }
      _currentPage = response.page;
      runInAction(() {
        results
          ..clear()
          ..addAll(response.items);
        hasMore.value = response.page * response.pageSize < response.total;
      });
    } on ApiException catch (error) {
      if (generation == _searchGeneration) {
        runInAction(() => errorMessage.value = error.message);
      }
    } catch (_) {
      if (generation == _searchGeneration) {
        runInAction(
          () => errorMessage.value = 'Could not search foods. Try again.',
        );
      }
    } finally {
      if (generation == _searchGeneration) {
        runInAction(() => isSearching.value = false);
      }
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isSearching.value || isLoadingMore.value) return;
    final searchQuery = query.value.trim();
    if (searchQuery.isEmpty) return;
    final generation = _searchGeneration;
    final nextPage = _currentPage + 1;

    runInAction(() => isLoadingMore.value = true);
    try {
      final response = await apiService.searchFoods(
        q: searchQuery,
        source: 'catalog',
        page: nextPage,
        pageSize: pageSize,
      );
      if (generation != _searchGeneration ||
          searchQuery != query.value.trim()) {
        return;
      }
      _currentPage = response.page;
      final existingIds = results.map((item) => item.id).toSet();
      runInAction(() {
        results.addAll(
          response.items.where((item) => existingIds.add(item.id)),
        );
        hasMore.value = response.page * response.pageSize < response.total;
      });
    } on ApiException catch (error) {
      if (generation == _searchGeneration) {
        runInAction(() => errorMessage.value = error.message);
      }
    } catch (_) {
      if (generation == _searchGeneration) {
        runInAction(() => errorMessage.value = 'Could not load more foods.');
      }
    } finally {
      runInAction(() => isLoadingMore.value = false);
    }
  }

  Future<bool> logPlannedMeal(
    PlannedMeal plannedMeal, {
    String? operationId,
  }) async {
    if (plannedMeal.status != PlannedMealStatus.planned || isLogging) {
      return false;
    }
    runInAction(() {
      loggingPlanOrder.value = plannedMeal.order;
      errorMessage.value = null;
      pendingMealName.value = plannedMeal.meal.name;
      pendingMealEmoji.value = plannedMeal.meal.emoji;
    });
    _lastAttempt = _MealLogAttempt.planned;
    _retryPlannedMeal = plannedMeal;
    _retryFood = null;
    _retryEstimateQuery = null;
    _retryOperationId = operationId ?? _uuid.v4();
    dashboardStore.clearLastLoggedMeal();
    try {
      await dashboardStore.addMeal(
        plannedMeal.meal,
        source: 'recommendation',
        intent: MealLogIntent.planned,
        slotId: plannedMeal.id,
        operationId: _retryOperationId,
      );
      _applyAdaptationMessage();
      return true;
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Could not log this meal.');
    } finally {
      runInAction(() => loggingPlanOrder.value = null);
    }
    return false;
  }

  Future<bool> logFood(
    FoodItem item, {
    PlannedMeal? replacedSlot,
    double servings = 1,
    String? operationId,
  }) async {
    if (isLogging) return false;
    runInAction(() {
      loggingFoodId.value = item.id;
      errorMessage.value = null;
      pendingMealName.value = item.name;
      pendingMealEmoji.value = item.emoji;
    });
    _lastAttempt = _MealLogAttempt.food;
    _retryPlannedMeal = null;
    _retryFood = item;
    _retryReplacedSlot = replacedSlot;
    _retryServings = servings;
    _retryEstimateQuery = null;
    _retryOperationId = operationId ?? _uuid.v4();
    dashboardStore.clearLastLoggedMeal();
    try {
      await _logAdHocFood(
        item,
        replacedSlot: replacedSlot,
        servings: servings,
        operationId: _retryOperationId,
      );
      _applyAdaptationMessage();
      return true;
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Could not log this food.');
    } finally {
      runInAction(() => loggingFoodId.value = null);
    }
    return false;
  }

  Future<bool> estimateAndLog() async {
    final searchQuery = query.value.trim();
    return _estimateAndLog(searchQuery);
  }

  Future<FoodItem?> estimateFoodForReview() async {
    final searchQuery = query.value.trim();
    if (searchQuery.length < 2 || isLogging) return null;
    runInAction(() {
      isEstimating.value = true;
      errorMessage.value = null;
    });
    try {
      return await apiService.estimateFood(searchQuery);
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Could not estimate this food.');
    } finally {
      runInAction(() => isEstimating.value = false);
    }
    return null;
  }

  Future<bool> _estimateAndLog(
    String searchQuery, {
    String? operationId,
  }) async {
    if (searchQuery.length < 2 || isLogging) return false;
    runInAction(() {
      isEstimating.value = true;
      errorMessage.value = null;
      pendingMealName.value = searchQuery;
      pendingMealEmoji.value = '✨';
    });
    _lastAttempt = _MealLogAttempt.estimate;
    _retryPlannedMeal = null;
    _retryFood = null;
    _retryEstimateQuery = searchQuery;
    _retryOperationId = operationId ?? _uuid.v4();
    dashboardStore.clearLastLoggedMeal();
    try {
      final item = await apiService.estimateFood(searchQuery);
      runInAction(() {
        pendingMealName.value = item.name;
        pendingMealEmoji.value = item.emoji;
      });
      await _logAdHocFood(item, operationId: _retryOperationId);
      _applyAdaptationMessage();
      return true;
    } on ApiException catch (error) {
      runInAction(() => errorMessage.value = error.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Could not estimate this food.');
    } finally {
      runInAction(() => isEstimating.value = false);
    }
    return false;
  }

  bool get canRetry => _lastAttempt != null && errorMessage.value != null;

  Future<bool> retryLastLog() {
    if (isLogging) return Future.value(false);
    switch (_lastAttempt) {
      case _MealLogAttempt.planned:
        final meal = _retryPlannedMeal;
        return meal == null
            ? Future.value(false)
            : logPlannedMeal(meal, operationId: _retryOperationId);
      case _MealLogAttempt.food:
        final food = _retryFood;
        return food == null
            ? Future.value(false)
            : logFood(
                food,
                replacedSlot: _retryReplacedSlot,
                servings: _retryServings,
                operationId: _retryOperationId,
              );
      case _MealLogAttempt.estimate:
        final estimateQuery = _retryEstimateQuery;
        return estimateQuery == null
            ? Future.value(false)
            : _estimateAndLog(estimateQuery, operationId: _retryOperationId);
      case null:
        return Future.value(false);
    }
  }

  Future<void> _logAdHocFood(
    FoodItem item, {
    PlannedMeal? replacedSlot,
    double servings = 1,
    String? operationId,
  }) {
    return dashboardStore.addMeal(
      Meal(
        name: item.name,
        emoji: item.emoji,
        calories: (item.calories * servings).round(),
        proteinG: (item.proteinG * servings).round(),
        carbsG: (item.carbsG * servings).round(),
        fatsG: (item.fatsG * servings).round(),
        servingSize: item.servingSize,
        servings: servings,
        servingUnit: item.servingSize,
        nutritionBasis: NutritionBasis(
          servingAmount: 1,
          servingUnit: item.servingSize,
          calories: item.calories,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatsG: item.fatsG,
        ),
      ),
      source: 'text',
      intent: replacedSlot == null
          ? MealLogIntent.extra
          : MealLogIntent.replacement,
      slotId: replacedSlot?.id,
      operationId: operationId,
    );
  }

  void _applyAdaptationMessage() {
    final status = dashboardStore.adaptationStatus.value;
    runInAction(() {
      adaptationMessage.value = switch (status) {
        AdaptationStatus.unavailable =>
          'Meal saved; update unavailable. You can retry without logging again.',
        AdaptationStatus.notNeeded => 'Meal saved. No plan changes are needed.',
        _ => null,
      };
    });
  }

  Future<bool> retryAdaptation() async {
    runInAction(() {
      adaptationMessage.value = null;
      errorMessage.value = null;
    });
    try {
      final result = await apiService.retryAdaptation(
        dayId: dashboardStore.activeDayId.value,
        expectedPlanRevision: dashboardStore.planRevision.value,
      );
      runInAction(() {
        dashboardStore.adaptationStatus.value = result.status;
        dashboardStore.pendingProposal.value = result.proposal;
      });
      _applyAdaptationMessage();
      return result.status != AdaptationStatus.unavailable;
    } on ApiException catch (error) {
      runInAction(() => adaptationMessage.value = error.message);
      return false;
    }
  }
}

enum _MealLogAttempt { planned, food, estimate }
