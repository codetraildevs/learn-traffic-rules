import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _refreshToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Initialize with stored tokens
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.tokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
  }

  // Set authentication tokens
  Future<void> setAuthTokens(String token, String refreshToken) async {
    _authToken = token;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  // Clear authentication tokens
  Future<void> clearAuthTokens() async {
    _authToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }

  // Generic HTTP request method
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final requestHeaders = {..._headers, ...?headers};

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Authentication API calls
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/login',
      body: request.toJson(),
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/register',
      body: request.toJson(),
    );
    return AuthResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> logout() async {
    return await _makeRequest('POST', '${AppConstants.authEndpoint}/logout');
  }

  Future<Map<String, dynamic>> refreshToken() async {
    if (_refreshToken == null) {
      throw ApiException(
          message: 'No refresh token available', statusCode: 401);
    }

    final response = await _makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/refresh-token',
      body: {'refreshToken': _refreshToken},
    );
    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(
      ForgotPasswordRequest request) async {
    return await _makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/forgot-password',
      body: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> resetPassword(
      ResetPasswordRequest request) async {
    return await _makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/reset-password',
      body: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> deleteAccount(
      DeleteAccountRequest request) async {
    return await _makeRequest(
      'DELETE',
      '${AppConstants.authEndpoint}/delete-account',
      body: request.toJson(),
    );
  }

  // Exam API calls
  Future<List<Exam>> getExams() async {
    final response = await _makeRequest('GET', AppConstants.examsEndpoint);
    final examsData = response['data'] as List;
    return examsData.map((exam) => Exam.fromJson(exam)).toList();
  }

  Future<Exam> getExam(String examId) async {
    final response =
        await _makeRequest('GET', '${AppConstants.examsEndpoint}/$examId');
    return Exam.fromJson(response['data']);
  }

  Future<List<Question>> getExamQuestions(String examId) async {
    final response = await _makeRequest(
        'GET', '${AppConstants.examsEndpoint}/$examId/questions');
    final questionsData = response['data'] as List;
    return questionsData
        .map((question) => Question.fromJson(question))
        .toList();
  }

  Future<ExamResult> submitExam(ExamSubmission submission) async {
    final response = await _makeRequest(
      'POST',
      '${AppConstants.examsEndpoint}/${submission.examId}/submit',
      body: submission.toJson(),
    );
    return ExamResult.fromJson(response['data']);
  }

  // Offline API calls
  Future<OfflineExamData> downloadExamData(String examId) async {
    final response = await _makeRequest(
        'GET', '${AppConstants.offlineEndpoint}/download/exam/$examId');
    return OfflineExamData.fromJson(response['data']);
  }

  Future<List<OfflineExamData>> downloadAllExams() async {
    final response = await _makeRequest(
        'GET', '${AppConstants.offlineEndpoint}/download/all');
    final examsData = response['data']['exams'] as List;
    return examsData.map((exam) => OfflineExamData.fromJson(exam)).toList();
  }

  Future<Map<String, dynamic>> checkForUpdates(DateTime lastSyncTime) async {
    return await _makeRequest(
      'POST',
      '${AppConstants.offlineEndpoint}/check-updates',
      body: {'lastSyncTime': lastSyncTime.toIso8601String()},
    );
  }

  Future<Map<String, dynamic>> syncExamResults(
      List<OfflineExamResult> results) async {
    return await _makeRequest(
      'POST',
      '${AppConstants.offlineEndpoint}/sync-results',
      body: {'results': results.map((r) => r.toJson()).toList()},
    );
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _makeRequest(
        'GET', '${AppConstants.offlineEndpoint}/sync-status');
  }

  Future<Map<String, dynamic>> updateLastSync() async {
    return await _makeRequest(
        'POST', '${AppConstants.offlineEndpoint}/update-sync');
  }

  // Payment API calls
  Future<Map<String, dynamic>> requestGlobalAccess() async {
    return await _makeRequest(
        'POST', '${AppConstants.paymentsEndpoint}/request');
  }

  Future<List<Map<String, dynamic>>> getUserPaymentRequests() async {
    final response =
        await _makeRequest('GET', '${AppConstants.paymentsEndpoint}/requests');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<List<Map<String, dynamic>>> getAllPaymentRequests() async {
    final response = await _makeRequest(
        'GET', '${AppConstants.paymentsEndpoint}/requests/all');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<Map<String, dynamic>> approvePaymentRequest(String requestId) async {
    return await _makeRequest(
        'PUT', '${AppConstants.paymentsEndpoint}/requests/$requestId/approve');
  }

  Future<Map<String, dynamic>> rejectPaymentRequest(
      String requestId, String reason) async {
    return await _makeRequest(
        'PUT', '${AppConstants.paymentsEndpoint}/requests/$requestId/reject',
        body: {'reason': reason});
  }

  Future<List<Map<String, dynamic>>> getUserAccessCodes() async {
    final response = await _makeRequest(
        'GET', '${AppConstants.paymentsEndpoint}/access-codes');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  // Analytics API calls
  Future<Map<String, dynamic>> getDashboardAnalytics({int days = 30}) async {
    return await _makeRequest(
        'GET', '${AppConstants.analyticsEndpoint}/dashboard?days=$days');
  }

  Future<Map<String, dynamic>> getUserPerformance({int days = 30}) async {
    return await _makeRequest(
        'GET', '${AppConstants.analyticsEndpoint}/user-performance?days=$days');
  }

  Future<Map<String, dynamic>> getExamAnalytics(String examId,
      {int days = 30}) async {
    return await _makeRequest(
        'GET', '${AppConstants.analyticsEndpoint}/exam/$examId?days=$days');
  }

  // Notification API calls
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _makeRequest(
      'GET',
      '${AppConstants.notificationsEndpoint}?page=$page&limit=$limit&unreadOnly=$unreadOnly',
    );
    return List<Map<String, dynamic>>.from(response['data']['notifications']);
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    return await _makeRequest(
        'PUT', '${AppConstants.notificationsEndpoint}/$notificationId/read');
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await _makeRequest(
        'PUT', '${AppConstants.notificationsEndpoint}/read-all');
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    return await _makeRequest(
        'GET', '${AppConstants.notificationsEndpoint}/preferences');
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    return await _makeRequest(
        'PUT', '${AppConstants.notificationsEndpoint}/preferences',
        body: preferences);
  }

  // Achievement API calls
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    final response =
        await _makeRequest('GET', AppConstants.achievementsEndpoint);
    return List<Map<String, dynamic>>.from(response['data']['achievements']);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String type = 'points',
    int limit = 10,
  }) async {
    final response = await _makeRequest('GET',
        '${AppConstants.achievementsEndpoint}/leaderboard?type=$type&limit=$limit');
    return List<Map<String, dynamic>>.from(response['data']['leaderboard']);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    return await _makeRequest(
        'GET', '${AppConstants.achievementsEndpoint}/stats');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
