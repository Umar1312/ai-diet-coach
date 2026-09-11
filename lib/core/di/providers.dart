import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/features/customize_day/models/custom_day_plan_request.dart';
import 'package:diet_coach_ai/features/meal_swap/models/meal_swap_models.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/history_response.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/onboarding_state.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';
import 'package:diet_coach_ai/shared/models/recommendation_models.dart';
import 'package:diet_coach_ai/shared/models/session_response.dart';
import 'package:diet_coach_ai/shared/models/subscription_status.dart';
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ),
);

final apiService = ApiService(
  dio,
  devToken: AppConstants.devBearerToken.isNotEmpty
      ? AppConstants.devBearerToken
      : null,
);

typedef AuthTokenProvider = Future<String?> Function({bool forceRefresh});

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({required this.code, required this.message, this.statusCode});
}

class ApiService {
  final Dio _dio;
  AuthTokenProvider? _authTokenProvider;
  Future<void>? _authTokenRefresh;
  int _authTokenProviderVersion = 0;

  ApiService(this._dio, {String? devToken}) {
    if (devToken != null && devToken.isNotEmpty) {
      setAuthToken(devToken);
    }
  }

  void setAuthTokenProvider(AuthTokenProvider? provider) {
    _authTokenProvider = provider;
    _authTokenProviderVersion++;
  }

  void setAuthToken(String token) {
    if (token.trim().isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> _refreshAuthToken({bool forceRefresh = false}) {
    final provider = _authTokenProvider;
    if (provider == null) return Future.value();

    final existingRefresh = _authTokenRefresh;
    if (existingRefresh != null) {
      if (!forceRefresh) return existingRefresh;
      return existingRefresh.then((_) => _refreshAuthToken(forceRefresh: true));
    }

    final refresh = () async {
      final providerVersion = _authTokenProviderVersion;
      final token = await provider(forceRefresh: forceRefresh);
      if (_authTokenProviderVersion == providerVersion) {
        setAuthToken(token ?? '');
      }
    }();
    _authTokenRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_authTokenRefresh, refresh)) {
        _authTokenRefresh = null;
      }
    });
  }

  bool _shouldRetryWithFreshToken(DioException e) {
    return _authTokenProvider != null && e.response?.statusCode == 401;
  }

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      await _refreshAuthToken();
      return await call();
    } on DioException catch (e) {
      if (_shouldRetryWithFreshToken(e)) {
        try {
          await _refreshAuthToken(forceRefresh: true);
          return await call();
        } on DioException catch (retryError) {
          final err = parseApiError(retryError);
          debugPrint(
            '🚨 API ERROR [${retryError.response?.statusCode}] ${retryError.requestOptions.method} ${retryError.requestOptions.path}\n'
            '   code: ${err.code}\n'
            '   message: ${err.message}\n'
            '   response: ${retryError.response?.data}',
          );
          throw err;
        }
      }

      final err = parseApiError(e);
      debugPrint(
        '🚨 API ERROR [${e.response?.statusCode}] ${e.requestOptions.method} ${e.requestOptions.path}\n'
        '   code: ${err.code}\n'
        '   message: ${err.message}\n'
        '   response: ${e.response?.data}',
      );
      throw err;
    }
  }

  Future<UserSetupResponse> setupUser(UserSetupRequest request) async {
    return _wrap(() async {
      final response = await _dio.post('/users/setup', data: request.toJson());
      return UserSetupResponse.fromJson(response.data);
    });
  }

  Future<PantryStarterPackResponse> fetchOnboardingStarterPack() async {
    return _wrap(() async {
      final response = await _dio.get('/users/onboarding/pantry-starter-pack');
      return PantryStarterPackResponse.fromJson(response.data);
    });
  }

  Future<OnboardingPantryResponse> completeOnboardingPantry({
    required bool skipped,
    List<String> selectedItemNames = const [],
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/users/onboarding/pantry-complete',
        data: {
          'decision': skipped ? 'skipped' : 'selected',
          'selected_item_names': selectedItemNames,
        },
      );
      return OnboardingPantryResponse.fromJson(response.data);
    });
  }

  Future<DailyPlan> fetchOnboardingPlanPreview() async {
    return _wrap(() async {
      final response = await _dio.post('/users/onboarding/plan-preview');
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<OnboardingStateResponse> completeOnboarding() async {
    return _wrap(() async {
      final response = await _dio.post('/users/onboarding/complete');
      return OnboardingStateResponse.fromJson(response.data);
    });
  }

  Future<DailyPlan> fetchDashboard({
    required String dayId,
    bool preferPantry = false,
  }) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/dashboard/state',
        queryParameters: {
          'day_id': dayId,
          if (preferPantry) 'prefer_pantry': 'true',
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<HistoryResponse> fetchHistory({int days = 7}) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/history',
        queryParameters: {'days': days},
      );
      return HistoryResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> logVision(
    String imagePath, {
    String? context,
    String? slot,
  }) async {
    return _wrap(() async {
      final map = <String, dynamic>{
        'image': await MultipartFile.fromFile(imagePath, filename: 'meal.jpg'),
      };
      if (context != null) map['context'] = context;
      if (slot != null) map['slot'] = slot;
      final formData = FormData.fromMap(map);
      final response = await _dio.post('/log/vision', data: formData);
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> logText(
    String description, {
    String? context,
    List<String>? pantryItemIds,
    String? slot,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/log/text',
        data: TextLogRequest(
          description: description,
          context: context,
          pantryItemIds: pantryItemIds,
          slot: slot,
        ).toJson(),
      );
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> logManual(ManualLogRequest request) async {
    return _wrap(() async {
      final response = await _dio.post('/log/manual', data: request.toJson());
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> createMealLog(MealLogMutationRequest request) async {
    return _wrap(() async {
      final response = await _dio.post('/meal-logs', data: request.toJson());
      return MealLogResponse.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<MealLogResponse> logRecommendation(
    LogRecommendationRequest request,
  ) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/log/recommendation',
        data: request.toJson(),
      );
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> editMeal(
    String mealId,
    MealEditRequest request,
  ) async {
    return _wrap(() async {
      final response = await _dio.patch(
        '/meal-logs/$mealId',
        data: request.toJson(),
      );
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<DailyPlan> deleteMeal(
    String mealId, {
    required String operationId,
    required String dayId,
    required int expectedPlanRevision,
  }) async {
    return _wrap(() async {
      final response = await _dio.delete(
        '/meal-logs/$mealId',
        data: {
          'operation_id': operationId,
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<SwapResponse> swapMeal(
    String currentMealName, {
    bool preferPantry = false,
    String? reason,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/recommendations/swap',
        data: {
          'current_meal_name': currentMealName,
          'reason': reason ?? 'user_swap',
          if (preferPantry) 'prefer_pantry': true,
        },
      );
      return SwapResponse.fromJson(response.data);
    });
  }

  Future<QuickActionResponse> quickAction(
    String action, {
    bool preferPantry = false,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/recommendations/quick-action',
        data: {'action': action, if (preferPantry) 'prefer_pantry': true},
      );
      return QuickActionResponse.fromJson(response.data);
    });
  }

  Future<CravingResponse> requestCraving(
    String cravingText, {
    List<String> tags = const [],
    bool preferPantry = false,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/recommendations/craving',
        data: CravingRequest(
          cravingText: cravingText,
          tags: tags,
          preferPantry: preferPantry,
        ).toJson(),
      );
      return CravingResponse.fromJson(response.data);
    });
  }

  Future<PantryListResponse> fetchPantry() async {
    return _wrap(() async {
      final response = await _dio.get('/pantry');
      return PantryListResponse.fromJson(response.data);
    });
  }

  Future<PantrySuggestionsResponse> fetchPantrySuggestions({
    int page = 1,
    int pageSize = 10,
    String? q,
  }) async {
    return _wrap(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (q != null && q.trim().isNotEmpty) {
        queryParams['q'] = q.trim();
      }
      final response = await _dio.get(
        '/pantry/suggestions',
        queryParameters: queryParams,
      );
      return PantrySuggestionsResponse.fromJson(response.data);
    });
  }

  Future<FoodSearchResponse> searchFoods({
    required String q,
    String source = 'all',
    int page = 1,
    int pageSize = 20,
  }) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/foods/search',
        queryParameters: {
          'q': q.trim(),
          'source': source,
          'page': page,
          'page_size': pageSize,
        },
      );
      return FoodSearchResponse.fromJson(response.data);
    });
  }

  Future<FoodItem> estimateFood(String query) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/foods/estimate',
        data: {'query': query.trim()},
      );
      return FoodItem.fromJson(response.data);
    });
  }

  Future<PantryItemResponse> addPantryItem(PantryCreateRequest request) async {
    return _wrap(() async {
      final response = await _dio.post('/pantry', data: request.toJson());
      return PantryItemResponse.fromJson(response.data);
    });
  }

  Future<PantryItemResponse> updatePantryItem(
    String id,
    PantryUpdateRequest request,
  ) async {
    return _wrap(() async {
      final response = await _dio.patch('/pantry/$id', data: request.toJson());
      return PantryItemResponse.fromJson(response.data);
    });
  }

  Future<void> deletePantryItem(String id) async {
    return _wrap(() async {
      await _dio.delete('/pantry/$id');
    });
  }

  Future<PantryStarterPackResponse> fetchStarterPack() async {
    return _wrap(() async {
      final response = await _dio.get('/pantry/starter-pack');
      return PantryStarterPackResponse.fromJson(response.data);
    });
  }

  // ── Day Plan (v2.1 proactive daily menu) ────────────────────────────────

  Future<DailyPlan> fetchDayPlan({required String dayId}) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/day-plan',
        queryParameters: {'day_id': dayId},
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> regenerateDayPlan({
    required String dayId,
    required int expectedPlanRevision,
    required String operationId,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/regenerate',
        data: {
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
          'operation_id': operationId,
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> saveCustomDayPlan(CustomDayPlanRequest request) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/custom',
        data: request.toJson(),
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> skipSlot(
    String slotId, {
    required String dayId,
    required int expectedPlanRevision,
    required String operationId,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/slots/$slotId/skip',
        data: {
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
          'operation_id': operationId,
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> protectSlot(
    String slotId, {
    required String dayId,
    required int expectedPlanRevision,
    required String operationId,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/slots/$slotId/protect',
        data: {
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
          'operation_id': operationId,
        },
      );
      return DailyPlan.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<DailyPlan> swapSlot(
    String slotId, {
    required String dayId,
    List<String>? excludeNames,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/slots/$slotId/swap',
        data: {
          'day_id': dayId,
          if (excludeNames != null && excludeNames.isNotEmpty)
            'exclude_names': excludeNames,
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<SlotAlternativesResponse> fetchSlotAlternatives(
    String slotId, {
    required String dayId,
    String reason = 'surprise_me',
    List<String> excludeNames = const [],
    bool preferPantry = true,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/slots/$slotId/alternatives',
        data: {
          'day_id': dayId,
          'reason': reason,
          'exclude_names': excludeNames,
          'count': 3,
          'prefer_pantry': preferPantry,
        },
      );
      return SlotAlternativesResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<SlotReplacementResponse> replacePlanSlot(
    String slotId, {
    required String dayId,
    required String expectedCurrentName,
    required Meal replacement,
    required bool rebalanceRemaining,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/slots/$slotId/replace',
        data: {
          'day_id': dayId,
          'expected_current_name': expectedCurrentName,
          'meal': replacement.toJson(),
          'rebalance_remaining': rebalanceRemaining,
        },
      );
      return SlotReplacementResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<DailyPlan> acceptProposal({
    required String proposalId,
    required String dayId,
    required int expectedPlanRevision,
    required String operationId,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/proposals/$proposalId/accept',
        data: {
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
          'operation_id': operationId,
        },
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> dismissProposal({
    required String proposalId,
    required String dayId,
    required int expectedPlanRevision,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/proposals/$proposalId/dismiss',
        data: {'day_id': dayId, 'expected_plan_revision': expectedPlanRevision},
      );
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<DailyPlan> regenerateProposal({
    required String proposalId,
    required String dayId,
    required int expectedPlanRevision,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/proposals/$proposalId/regenerate',
        data: {'day_id': dayId, 'expected_plan_revision': expectedPlanRevision},
      );
      return DailyPlan.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<AdaptationResult> retryAdaptation({
    required String dayId,
    required int expectedPlanRevision,
    String trigger = 'retry',
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/day-plan/adaptation/check',
        data: {
          'day_id': dayId,
          'expected_plan_revision': expectedPlanRevision,
          'trigger': trigger,
          'excluded_proposal_ids': const <String>[],
        },
      );
      return AdaptationResult.fromJson(response.data as Map<String, dynamic>);
    });
  }

  // Legacy plan endpoint (still used for backward compatibility)
  Future<DailyPlan> fetchPlan() async {
    return _wrap(() async {
      final response = await _dio.get('/plan');
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<User> fetchProfile() async {
    return _wrap(() async {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data);
    });
  }

  Future<SessionResponse> fetchSession() async {
    return _wrap(() async {
      final response = await _dio.get('/auth/session');
      return SessionResponse.fromJson(response.data);
    });
  }

  Future<SubscriptionStatus> fetchSubscriptionStatus() async {
    return _wrap(() async {
      final response = await _dio.get('/subscriptions/me');
      return SubscriptionStatus.fromJson(response.data);
    });
  }

  Future<SubscriptionStatus> syncSubscriptionStatus() async {
    return _wrap(() async {
      final response = await _dio.post('/subscriptions/me/sync');
      return SubscriptionStatus.fromJson(response.data);
    });
  }

  Future<User> updateProfile(ProfilePatchRequest request) async {
    return _wrap(() async {
      final response = await _dio.patch('/users/me', data: request.toJson());
      return User.fromJson(response.data);
    });
  }

  /// Permanently removes the authenticated user's application data and
  /// Firebase identity. Store subscriptions must be cancelled separately.
  Future<void> deleteAccount() async {
    return _wrap(() async {
      await _dio.delete('/users/me');
    });
  }
}

class ProfilePatchRequest {
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? goal;
  final List<String>? dietaryRestrictions;
  final String? timezone;
  final String? country;
  final List<String>? preferredCuisines;

  const ProfilePatchRequest({
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.goal,
    this.dietaryRestrictions,
    this.timezone,
    this.country,
    this.preferredCuisines,
  });

  Map<String, dynamic> toJson() => {
    if (gender != null) 'gender': gender,
    if (age != null) 'age': age,
    if (heightCm != null) 'height_cm': heightCm,
    if (weightKg != null) 'weight_kg': weightKg,
    if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
    if (activityLevel != null) 'activity_level': activityLevel,
    if (goal != null) 'goal': goal,
    if (dietaryRestrictions != null)
      'dietary_restrictions': dietaryRestrictions,
    if (timezone != null) 'timezone': timezone,
    if (country != null) 'country': country,
    if (preferredCuisines != null) 'preferred_cuisines': preferredCuisines,
  };
}

/// Parses a DioException into a user-friendly ApiException with the API error code.
ApiException parseApiError(DioException e) {
  final data = e.response?.data;
  // FastAPI HTTPException responses wrap the app error inside `detail`, while
  // the generic exception handler returns the same error at the top level.
  final detail = data is Map<String, dynamic>
      ? data['detail'] as Map<String, dynamic>?
      : null;
  final errorObj = data is Map<String, dynamic>
      ? (data['error'] as Map<String, dynamic>? ??
            detail?['error'] as Map<String, dynamic>?)
      : null;
  final code = errorObj?['code'] as String?;
  final serverMessage = errorObj?['message'] as String?;

  switch (code) {
    case 'unauthorized':
      return ApiException(
        code: 'unauthorized',
        message: serverMessage ?? 'Session expired. Please sign in again.',
        statusCode: e.response?.statusCode,
      );
    case 'user_not_found':
      return ApiException(
        code: 'user_not_found',
        message: serverMessage ?? 'User not found. Complete setup first.',
        statusCode: e.response?.statusCode,
      );
    case 'validation_error':
      return ApiException(
        code: 'validation_error',
        message: serverMessage ?? 'Invalid input. Please check your data.',
        statusCode: e.response?.statusCode,
      );
    case 'rate_limited':
      return ApiException(
        code: 'rate_limited',
        message: 'Too many requests. Please slow down.',
        statusCode: e.response?.statusCode,
      );
    case 'subscription_required':
      return ApiException(
        code: 'subscription_required',
        message: serverMessage ?? 'An active subscription is required.',
        statusCode: e.response?.statusCode,
      );
    case 'analysis_failed':
      return ApiException(
        code: 'analysis_failed',
        message: 'AI analysis unavailable. Try again later.',
        statusCode: e.response?.statusCode,
      );
    case 'internal_error':
      return ApiException(
        code: 'internal_error',
        message: 'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode,
      );
    default:
      return ApiException(
        code: code ?? 'unknown',
        message: serverMessage ?? 'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode,
      );
  }
}
