import 'package:dio/dio.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';
import 'package:diet_coach_ai/shared/models/recommended_dish.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ),
);

final apiService = ApiService(dio);

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({required this.code, required this.message, this.statusCode});
}

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<UserSetupResponse> setupUser(UserSetupRequest request) async {
    final response = await _dio.post('/users/setup', data: request.toJson());
    return UserSetupResponse.fromJson(response.data);
  }

  Future<DashboardState> fetchDashboard() async {
    final response = await _dio.get('/dashboard/state');
    return DashboardState.fromJson(response.data);
  }

  Future<List<DashboardState>> fetchHistory({int days = 7}) async {
    final response = await _dio.get(
      '/history',
      queryParameters: {'days': days},
    );
    return (response.data as List)
        .map((e) => DashboardState.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealLogResponse> logVision(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'meal.jpg'),
    });
    final response = await _dio.post('/log/vision', data: formData);
    return MealLogResponse.fromJson(response.data);
  }

  Future<MealLogResponse> logText(String description) async {
    final response = await _dio.post(
      '/log/text',
      data: {'description': description},
    );
    return MealLogResponse.fromJson(response.data);
  }

  Future<MenuScanResponse> scanMenu(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'menu.jpg'),
    });
    final response = await _dio.post('/scan/menu', data: formData);
    return MenuScanResponse.fromJson(response.data);
  }
}

/// Parses a DioException into a user-friendly ApiException with the API error code.
/// Handles all 6 error codes from the PRD.
ApiException parseApiError(DioException e) {
  final data = e.response?.data;
  final code = (data is Map<String, dynamic>) ? data['code'] as String? : null;
  final serverMessage = (data is Map<String, dynamic>)
      ? data['message'] as String?
      : null;

  switch (code) {
    case 'auth_invalid':
      return ApiException(
        code: 'auth_invalid',
        message: serverMessage ?? 'Session expired. Please sign in again.',
        statusCode: e.response?.statusCode,
      );
    case 'user_not_found':
      return ApiException(
        code: 'user_not_found',
        message: serverMessage ?? 'User not found.',
        statusCode: e.response?.statusCode,
      );
    case 'image_too_large':
      return ApiException(
        code: 'image_too_large',
        message: 'Image too large. Try a closer photo.',
        statusCode: e.response?.statusCode,
      );
    case 'menu_unreadable':
      return ApiException(
        code: 'menu_unreadable',
        message: "Couldn't read that menu. Try a clearer photo.",
        statusCode: e.response?.statusCode,
      );
    case 'log_conflict':
      return ApiException(
        code: 'log_conflict',
        message: serverMessage ?? 'Conflict. Retrying...',
        statusCode: e.response?.statusCode,
      );
    case 'ai_unavailable':
      return ApiException(
        code: 'ai_unavailable',
        message: 'AI is taking too long. Try again in a moment.',
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
