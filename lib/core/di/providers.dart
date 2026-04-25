import 'package:dio/dio.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/history_response.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';
import 'package:diet_coach_ai/shared/models/recommendation_models.dart';
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

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({required this.code, required this.message, this.statusCode});
}

class ApiService {
  final Dio _dio;

  ApiService(this._dio, {String? devToken}) {
    if (devToken != null && devToken.isNotEmpty) {
      setAuthToken(devToken);
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw parseApiError(e);
    }
  }

  Future<UserSetupResponse> setupUser(UserSetupRequest request) async {
    return _wrap(() async {
      final response = await _dio.post('/users/setup', data: request.toJson());
      return UserSetupResponse.fromJson(response.data);
    });
  }

  Future<DailyPlan> fetchDashboard() async {
    return _wrap(() async {
      final response = await _dio.get('/dashboard/state');
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

  Future<MealLogResponse> logVision(String imagePath, {String? context}) async {
    return _wrap(() async {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'meal.jpg'),
        if (context != null) 'context': context,
      });
      final response = await _dio.post('/log/vision', data: formData);
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<MealLogResponse> logText(String description, {String? context}) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/log/text',
        data: TextLogRequest(
          description: description,
          context: context,
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
      final response = await _dio.patch('/log/$mealId', data: request.toJson());
      return MealLogResponse.fromJson(response.data);
    });
  }

  Future<DailyPlan> deleteMeal(String mealId) async {
    return _wrap(() async {
      final response = await _dio.delete('/log/$mealId');
      return DailyPlan.fromJson(response.data);
    });
  }

  Future<SwapResponse> swapMeal(String currentMealName) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/recommendations/swap',
        data: {'current_meal_name': currentMealName, 'reason': 'user_swap'},
      );
      return SwapResponse.fromJson(response.data);
    });
  }

  Future<QuickActionResponse> quickAction(String action) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/recommendations/quick-action',
        data: {'action': action},
      );
      return QuickActionResponse.fromJson(response.data);
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
  }) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/pantry/suggestions',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return PantrySuggestionsResponse.fromJson(response.data);
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
      final response = await _dio.put('/pantry/$id', data: request.toJson());
      return PantryItemResponse.fromJson(response.data);
    });
  }

  Future<void> deletePantryItem(String id) async {
    return _wrap(() async {
      await _dio.delete('/pantry/$id');
    });
  }

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

  Future<User> updateProfile(ProfilePatchRequest request) async {
    return _wrap(() async {
      final response = await _dio.patch('/users/me', data: request.toJson());
      return User.fromJson(response.data);
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
  };
}

/// Parses a DioException into a user-friendly ApiException with the API error code.
ApiException parseApiError(DioException e) {
  final data = e.response?.data;
  // Backend wraps errors in {"error": {"code": "...", "message": "..."}}
  final errorObj = (data is Map<String, dynamic>)
      ? data['error'] as Map<String, dynamic>?
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
