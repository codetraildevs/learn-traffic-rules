import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:learn_traffic_rules/models/question_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/exam_model.dart' hide Question;
import 'network_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _refreshToken;
  final NetworkService _networkService = NetworkService();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Public method to get headers for external use
  Map<String, String> getHeaders() => _headers;

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
  Future<Map<String, dynamic>> makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int maxRetries = 3,
    Duration? requestTimeout,
  }) async {
    final timeout = requestTimeout ?? const Duration(seconds: 30);
    // Check network connectivity first
    if (!await _networkService.hasInternetConnection()) {
      throw ApiException(
        message:
            'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    }

    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
        final requestHeaders = {..._headers, ...?headers};

        debugPrint(
          '🔍 API SERVICE DEBUG - Making request (attempt ${retryCount + 1}):',
        );
        debugPrint('   Method: $method');
        debugPrint('   URL: $uri');
        debugPrint('   Headers: $requestHeaders');
        debugPrint(
          '   Auth token present: ${requestHeaders.containsKey('Authorization')}',
        );

        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(uri, headers: requestHeaders)
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw Exception('Request timeout');
                  },
                );
            break;
          case 'POST':
            response = await http
                .post(
                  uri,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw Exception('Request timeout');
                  },
                );
            break;
          case 'PUT':
            response = await http
                .put(
                  uri,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw Exception('Request timeout');
                  },
                );
            break;
          case 'PATCH':
            response = await http
                .patch(
                  uri,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw Exception('Request timeout');
                  },
                );
            break;
          case 'DELETE':
            response = await http
                .delete(uri, headers: requestHeaders)
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw Exception('Request timeout');
                  },
                );
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        // Check if response body is not empty before parsing
        if (response.body.isEmpty) {
          throw ApiException(
            message: 'Empty response from server',
            statusCode: response.statusCode,
          );
        }

        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          // Handle non-JSON responses (like rate limit messages)
          debugPrint('⚠️  Non-JSON response received: ${response.body}');

          // Check if it's a rate limit error
          if (response.statusCode == 429) {
            throw ApiException(
              message: 'Rate limit exceeded. Please wait before trying again.',
              statusCode: response.statusCode,
            );
          }

          // Check if it's a plain text error message
          if (response.body.toLowerCase().contains('too many requests')) {
            throw ApiException(
              message: 'Too many requests. Please wait before trying again.',
              statusCode: response.statusCode,
            );
          }

          // For other non-JSON responses, try to extract meaningful error
          String errorMessage = response.body;
          if (errorMessage.length > 100) {
            errorMessage = '${errorMessage.substring(0, 100)}...';
          }

          throw ApiException(
            message: 'Server returned non-JSON response: $errorMessage',
            statusCode: response.statusCode,
          );
        }

        debugPrint('🔍 API SERVICE DEBUG - Response received:');
        debugPrint('   Status Code: $response.statusCode');
        debugPrint('   Response Body: $responseData');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return responseData;
        } else {
          debugPrint('❌ API SERVICE ERROR - Request failed');
          throw ApiException(
            message: responseData['message'] ?? 'Request failed',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        retryCount++;
        debugPrint('❌ API SERVICE ERROR - Attempt $retryCount failed: $e');

        // Don't retry rate limit errors (429) - they need user action
        if (e is ApiException && e.statusCode == 429) {
          debugPrint('🚫 Rate limit exceeded, not retrying');
          rethrow;
        }

        if (retryCount >= maxRetries) {
          if (e is ApiException) rethrow;
          throw ApiException(
            message: 'Network error after $maxRetries attempts: $e',
            statusCode: 0,
          );
        }

        // Wait before retrying (exponential backoff)
        // Longer delay for server errors (5xx)
        int delaySeconds = retryCount * 2;
        if (e is ApiException && e.statusCode >= 500) {
          delaySeconds = retryCount * 3; // Longer delay for server errors
        }

        await Future.delayed(Duration(seconds: delaySeconds));
        debugPrint(
          '🔄 API SERVICE - Retrying request (attempt ${retryCount + 1})',
        );
      }
    }

    throw ApiException(message: 'Max retries exceeded', statusCode: 0);
  }

  // Authentication API calls
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/login',
      body: request.toJson(),
    );

    // Debug logging to see raw API response
    debugPrint('🔍 RAW LOGIN API RESPONSE:');
    debugPrint('   response: $response');
    debugPrint('   response type: $response.runtimeType');

    try {
      final authResponse = AuthResponse.fromJson(response);
      debugPrint(
        '   parsed AuthResponse: success=$response.success, message=$response.message',
      );
      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('   JSON parsing error: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/register',
      body: request.toJson(),
    );

    // Debug logging to see raw API response
    debugPrint('🔍 RAW API RESPONSE:');
    debugPrint('   response: $response');
    debugPrint('   response type: $response.runtimeType');

    try {
      final authResponse = AuthResponse.fromJson(response);
      debugPrint(
        '   parsed AuthResponse: success=$response.success, message=$response.message',
      );
      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('   JSON parsing error: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout(String deviceId) async {
    return await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/logout',
      headers: {'device-id': deviceId},
    );
  }

  Future<Map<String, dynamic>> refreshToken() async {
    if (_refreshToken == null) {
      throw ApiException(
        message: 'No refresh token available',
        statusCode: 401,
      );
    }

    final response = await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/refresh-token',
      body: {'refreshToken': _refreshToken},
    );
    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    return await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/forgot-password',
      body: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> resetPassword(
    ResetPasswordRequest request,
  ) async {
    return await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/reset-password',
      body: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> deleteAccount(String phoneNumber) async {
    return await makeRequest(
      'POST',
      '${AppConstants.authEndpoint}/delete-account',
      body: {'phoneNumber': phoneNumber},
    );
  }

  // Notification API calls
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    String? type,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'unreadOnly': unreadOnly.toString(),
    };

    if (type != null) queryParams['type'] = type;
    if (category != null) queryParams['category'] = category;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return await makeRequest('GET', '/notifications?$queryString');
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
  ) async {
    return await makeRequest('PUT', '/notifications/$notificationId/read');
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await makeRequest('PUT', '/notifications/read-all');
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    return await makeRequest('GET', '/notifications/preferences');
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    return await makeRequest(
      'PUT',
      '/notifications/preferences',
      body: preferences,
    );
  }

  Future<Map<String, dynamic>> createStudyReminder({
    required String reminderTime,
    required List<String> daysOfWeek,
    int studyGoalMinutes = 30,
    String timezone = 'UTC',
  }) async {
    return await makeRequest(
      'POST',
      '/notifications/study-reminder',
      body: {
        'reminderTime': reminderTime,
        'daysOfWeek': daysOfWeek,
        'studyGoalMinutes': studyGoalMinutes,
        'timezone': timezone,
      },
    );
  }

  Future<Map<String, dynamic>> getStudyReminder() async {
    return await makeRequest('GET', '/notifications/study-reminder');
  }

  Future<Map<String, dynamic>> updateStudyReminder(
    String reminderId,
    Map<String, dynamic> updateData,
  ) async {
    return await makeRequest(
      'PUT',
      '/notifications/study-reminder/$reminderId',
      body: updateData,
    );
  }

  Future<Map<String, dynamic>> deleteStudyReminder(String reminderId) async {
    return await makeRequest(
      'DELETE',
      '/notifications/study-reminder/$reminderId',
    );
  }

  // Exam API calls
  Future<List<Exam>> getExams() async {
    final response = await makeRequest('GET', AppConstants.examsEndpoint);
    final examsData = response['data'] as List;
    return examsData.map((exam) => Exam.fromJson(exam)).toList();
  }

  Future<Exam> getExam(String examId) async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.examsEndpoint}/$examId',
    );
    return Exam.fromJson(response['data']);
  }

  Future<List<Question>> getExamQuestions(String examId) async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.examsEndpoint}/$examId/questions',
    );
    final questionsData = response['data'] as List;
    return questionsData
        .map((question) => Question.fromJson(question))
        .toList();
  }

  Future<ExamResult> submitExam(ExamSubmission submission) async {
    final response = await makeRequest(
      'POST',
      '${AppConstants.examsEndpoint}/submit',
      body: submission.toJson(),
    );
    return ExamResult.fromJson(response['data']);
  }

  // Payment API calls
  Future<Map<String, dynamic>> requestGlobalAccess() async {
    return await makeRequest(
      'POST',
      '${AppConstants.paymentsEndpoint}/request',
    );
  }

  Future<List<Map<String, dynamic>>> getUserPaymentRequests() async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.paymentsEndpoint}/requests',
    );
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<List<Map<String, dynamic>>> getAllPaymentRequests() async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.paymentsEndpoint}/requests/all',
    );
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<Map<String, dynamic>> approvePaymentRequest(String requestId) async {
    return await makeRequest(
      'PUT',
      '${AppConstants.paymentsEndpoint}/requests/$requestId/approve',
    );
  }

  Future<Map<String, dynamic>> rejectPaymentRequest(
    String requestId,
    String reason,
  ) async {
    return await makeRequest(
      'PUT',
      '${AppConstants.paymentsEndpoint}/requests/$requestId/reject',
      body: {'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> getUserAccessCodes() async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.accessCodesEndpoint}/access-codes',
    );
    return List<Map<String, dynamic>>.from(response['data']);
  }

  // Analytics API calls
  Future<Map<String, dynamic>> getDashboardAnalytics({int days = 30}) async {
    return await makeRequest(
      'GET',
      '${AppConstants.analyticsEndpoint}/dashboard?days=$days',
    );
  }

  Future<Map<String, dynamic>> getUserPerformance({int days = 30}) async {
    return await makeRequest(
      'GET',
      '${AppConstants.analyticsEndpoint}/user-performance?days=$days',
    );
  }

  Future<Map<String, dynamic>> getExamAnalytics(
    String examId, {
    int days = 30,
  }) async {
    return await makeRequest(
      'GET',
      '${AppConstants.analyticsEndpoint}/exam/$examId?days=$days',
    );
  }

  // Notification API calls
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.notificationsEndpoint}?page=$page&limit=$limit&unreadOnly=$unreadOnly',
    );
    return List<Map<String, dynamic>>.from(response['data']['notifications']);
  }

  // Achievement API calls
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    final response = await makeRequest(
      'GET',
      AppConstants.achievementsEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['data']['achievements']);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String type = 'points',
    int limit = 10,
  }) async {
    final response = await makeRequest(
      'GET',
      '${AppConstants.achievementsEndpoint}/leaderboard?type=$type&limit=$limit',
    );
    return List<Map<String, dynamic>>.from(response['data']['leaderboard']);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    return await makeRequest(
      'GET',
      '${AppConstants.achievementsEndpoint}/stats',
    );
  }

  /// Upload file to server (multipart form)
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String? examId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

      var request = http.MultipartRequest('POST', uri);

      // Add headers (without Content-Type for multipart)
      request.headers.addAll({
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      });

      // Get file extension to determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String? contentType;

      switch (fileExtension) {
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // For bulk upload endpoints, try different field names
      String fieldName;
      if (endpoint.contains('/bulk-upload/')) {
        if (endpoint.contains('/csv')) {
          fieldName = 'file'; // CSV endpoint expects 'file'
        } else {
          fieldName = 'questions'; // JSON endpoint expects 'questions'
        }
      } else {
        fieldName = 'questions'; // Default for other endpoints
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Add exam ID for bulk uploads if provided
      if (endpoint.contains('/bulk-upload/') && examId != null) {
        request.fields['examId'] = examId;
      }

      debugPrint('📤 FILE UPLOAD: Uploading to $endpoint');
      debugPrint('   File: $file.path');
      debugPrint('   Content Type: $contentType');
      debugPrint('   Field Name: $fieldName');
      debugPrint('   Additional Fields: ${request.fields}');
      debugPrint('   Headers: ${request.headers}');
      debugPrint('   Files count: ${request.files.length}');
      debugPrint('   Request URL: $uri');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 FILE UPLOAD: Response status: $response.statusCode');
      debugPrint('📤 FILE UPLOAD: Response body: $response.body');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        try {
          final errorBody = json.decode(response.body);
          debugPrint('📤 FILE UPLOAD ERROR: $errorBody');
          throw ApiException(
            message: errorBody['message'] ?? 'Upload failed',
            statusCode: response.statusCode,
          );
        } catch (e) {
          debugPrint(
            '📤 FILE UPLOAD ERROR: Failed to parse error response: $e',
          );
          throw ApiException(
            message:
                'Upload failed with status ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ FILE UPLOAD ERROR: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// Upload file as raw data (alternative method)
  Future<Map<String, dynamic>> uploadFileRaw(
    String endpoint,
    File file, {
    String? examId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

      // Read file content
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;

      // Determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String contentType;

      switch (fileExtension) {
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      debugPrint('📤 FILE UPLOAD RAW: Uploading to $endpoint');
      debugPrint('   File: $file.path');
      debugPrint('   Content Type: $contentType');
      debugPrint('   File Size: ${fileBytes.length} bytes');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': contentType,
          'Content-Disposition': 'attachment; filename="$fileName"',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: fileBytes,
      );

      debugPrint('📤 FILE UPLOAD RAW: Response status: $response.statusCode');
      debugPrint('📤 FILE UPLOAD RAW: Response body: $response.body');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        try {
          final errorBody = json.decode(response.body);
          debugPrint('📤 FILE UPLOAD RAW ERROR: $errorBody');
          throw ApiException(
            message: errorBody['message'] ?? 'Upload failed',
            statusCode: response.statusCode,
          );
        } catch (e) {
          debugPrint(
            '📤 FILE UPLOAD RAW ERROR: Failed to parse error response: $e',
          );
          throw ApiException(
            message:
                'Upload failed with status ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ FILE UPLOAD RAW ERROR: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// Upload file as JSON payload with base64 encoding
  Future<Map<String, dynamic>> uploadFileJson(
    String endpoint,
    File file, {
    String? examId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

      // Read file content and encode as base64
      final fileBytes = await file.readAsBytes();
      final base64Content = base64Encode(fileBytes);
      final fileName = file.path.split('/').last;

      // Determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String contentType;

      switch (fileExtension) {
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      final requestBody = {
        'filename': fileName,
        'content': base64Content,
        'contentType': contentType,
        'size': fileBytes.length,
        if (examId != null) 'examId': examId,
      };

      debugPrint('📤 FILE UPLOAD JSON: Uploading to $endpoint');
      debugPrint('   File: $file.path');
      debugPrint('   Content Type: $contentType');
      debugPrint('   File Size: ${fileBytes.length} bytes');
      debugPrint('   Base64 Length: ${base64Content.length}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📤 FILE UPLOAD JSON: Response status: $response.statusCode');
      debugPrint('📤 FILE UPLOAD JSON: Response body: $response.body');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        try {
          final errorBody = json.decode(response.body);
          debugPrint('📤 FILE UPLOAD JSON ERROR: $errorBody');
          throw ApiException(
            message: errorBody['message'] ?? 'Upload failed',
            statusCode: response.statusCode,
          );
        } catch (e) {
          debugPrint(
            '📤 FILE UPLOAD JSON ERROR: Failed to parse error response: $e',
          );
          throw ApiException(
            message:
                'Upload failed with status ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ FILE UPLOAD JSON ERROR: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
