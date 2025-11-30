import 'package:flutter/material.dart';

import '../models/user_management_model.dart';
import '../models/access_code_model.dart';
import '../models/free_exam_model.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

class UserManagementService {
  final ApiService _apiService = ApiService();

  // Get all users with access code statistics
  Future<UserListResponse> getAllUsers({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    String filter = '', // 'with_code', 'without_code', 'called', 'not_called'
    String? startDate, // ISO date string (YYYY-MM-DD)
    String? endDate, // ISO date string (YYYY-MM-DD)
    bool filterByToday = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search.isNotEmpty) 'search': search,
      if (role.isNotEmpty) 'role': role,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (filter.isNotEmpty) 'filter': filter,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'filterByToday': filterByToday.toString(),
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/users?$queryString',
    );

    return UserListResponse.fromJson(response);
  }

  // Get user details with access codes
  Future<UserDetailsResponse> getUserDetails(String userId) async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/users/$userId',
    );

    return UserDetailsResponse.fromJson(response);
  }

  // Get user's access codes
  Future<UserAccessCodesResponse> getUserAccessCodes(
    String userId, {
    int page = 1,
    int limit = 20,
    String status = '',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status.isNotEmpty) 'status': status,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/users/$userId/access-codes?$queryString',
    );

    return UserAccessCodesResponse.fromJson(response);
  }

  // Create access code for specific user
  Future<CreateAccessCodeForUserResponse> createAccessCodeForUser(
    String userId,
    double paymentAmount,
  ) async {
    try {
      debugPrint(
        "🔍 Creating access code for user: $userId with amount: $paymentAmount",
      );

      final response = await _apiService.makeRequest(
        'POST',
        '${AppConstants.userManagementEndpoint}/users/$userId/access-codes',
        body: CreateAccessCodeForUserRequest(
          paymentAmount: paymentAmount,
        ).toJson(),
      );

      debugPrint("🔍 Access code response: $response");

      return CreateAccessCodeForUserResponse.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error creating access code: $e");
      rethrow;
    }
  }

  // Toggle user active status
  Future<Map<String, dynamic>> toggleUserStatus(
    String userId,
    bool isActive,
  ) async {
    final response = await _apiService.makeRequest(
      'PUT',
      '${AppConstants.userManagementEndpoint}/users/$userId/toggle-status',
      body: ToggleUserStatusRequest(isActive: isActive).toJson(),
    );

    return response;
  }

  // Get user and access code statistics
  Future<UserStatisticsResponse> getUserStatistics() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/statistics',
    );

    return UserStatisticsResponse.fromJson(response);
  }

  // Get payment tiers
  Future<PaymentTiersResponse> getPaymentTiers() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/payment-tiers',
    );

    return PaymentTiersResponse.fromJson(response);
  }

  // Validate access code (for users)
  Future<AccessCodeResponse> validateAccessCode(String code) async {
    final response = await _apiService.makeRequest(
      'POST',
      '${AppConstants.accessCodesEndpoint}/validate',
      body: ValidateAccessCodeRequest(code: code).toJson(),
    );

    return AccessCodeResponse.fromJson(response);
  }

  // Get current user's access codes
  Future<AccessCodeListResponse> getMyAccessCodes() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.accessCodesEndpoint}/my-codes',
    );

    return AccessCodeListResponse.fromJson(response);
  }

  // Get user dashboard data
  Future<Map<String, dynamic>> getUserDashboard() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/dashboard',
    );

    return response;
  }

  // Get individual user statistics (Admin/Manager only)
  Future<Map<String, dynamic>> getUserIndividualStatistics(
    String userId,
  ) async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/users/$userId/statistics',
    );

    return response;
  }

  // Get free exams for users without access codes
  Future<FreeExamResponse> getFreeExams({String? examType}) async {
    String url = '${AppConstants.userManagementEndpoint}/free-exams';
    if (examType != null && examType.isNotEmpty) {
      url += '?examType=$examType';
    }

    final response = await _apiService.makeRequest('GET', url);

    return FreeExamResponse.fromJson(response);
  }

  // Mark user as called
  Future<Map<String, dynamic>> markUserAsCalled(String userId) async {
    final response = await _apiService.makeRequest(
      'POST',
      '${AppConstants.userManagementEndpoint}/users/$userId/mark-called',
    );
    return response;
  }

  // Get all called users from server
  Future<Map<String, String>> getCalledUsers() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/called-users',
    );
    if (response['success'] == true && response['data'] != null) {
      final calledUsersMap = response['data']['calledUsers'] as Map<String, dynamic>;
      // Convert to Map<String, String>
      return calledUsersMap.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }

  // Sync call tracking with server
  Future<Map<String, String>> syncCallTracking(Map<String, String> localCalledUsers) async {
    try {
      final response = await _apiService.makeRequest(
        'POST',
        '${AppConstants.userManagementEndpoint}/sync-call-tracking',
        body: {
          'calledUsers': localCalledUsers,
        },
      );
      if (response['success'] == true && response['data'] != null) {
        final calledUsersMap = response['data']['calledUsers'] as Map<String, dynamic>;
        // Convert to Map<String, String>
        return calledUsersMap.map((key, value) => MapEntry(key, value.toString()));
      }
      return localCalledUsers; // Return local if sync fails
    } catch (e) {
      debugPrint('❌ Error syncing call tracking: $e');
      return localCalledUsers; // Return local if sync fails
    }
  }

  // Submit free exam result
  Future<SubmitFreeExamResponse> submitFreeExam(
    String examId,
    Map<String, String> answers, {
    int? timeSpent,
  }) async {
    final response = await _apiService.makeRequest(
      'POST',
      '${AppConstants.userManagementEndpoint}/submit-free-exam',
      body: SubmitFreeExamRequest(
        examId: examId,
        answers: answers,
        timeSpent: timeSpent,
      ).toJson(),
    );

    return SubmitFreeExamResponse.fromJson(response);
  }

  // Get my remaining days
  Future<RemainingDaysResponse> getMyRemainingDays() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/my-remaining-days',
    );

    return RemainingDaysResponse.fromJson(response);
  }

  // Get payment instructions
  Future<PaymentInstructionsResponse> getPaymentInstructions() async {
    final response = await _apiService.makeRequest(
      'GET',
      '${AppConstants.userManagementEndpoint}/payment-instructions',
    );

    return PaymentInstructionsResponse.fromJson(response);
  }

  // Get all access codes (Admin only)
  Future<AccessCodeListResponse> getAllAccessCodes() async {
    final response = await _apiService.makeRequest(
      'GET',
      AppConstants.accessCodesEndpoint,
    );
    return AccessCodeListResponse.fromJson(response);
  }

  // Toggle access code block status
  Future<Map<String, dynamic>> toggleAccessCodeBlockStatus(
    String codeId,
    bool isBlocked,
  ) async {
    return await _apiService.makeRequest(
      'PUT',
      '${AppConstants.accessCodesEndpoint}/$codeId/toggle-block',
      body: {'isBlocked': isBlocked},
    );
  }

  // Delete access code
  Future<Map<String, dynamic>> deleteAccessCode(String codeId) async {
    return await _apiService.makeRequest(
      'DELETE',
      '${AppConstants.accessCodesEndpoint}/$codeId',
    );
  }

  // Block/Unblock user
  Future<Map<String, dynamic>> blockUser(
    String userId,
    bool isBlocked, {
    String? blockReason,
  }) async {
    return await _apiService.makeRequest(
      'PUT',
      '${AppConstants.userManagementEndpoint}/$userId/block',
      body: {
        'isBlocked': isBlocked,
        if (blockReason != null) 'blockReason': blockReason,
      },
    );
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    return await _apiService.makeRequest(
      'DELETE',
      '${AppConstants.userManagementEndpoint}/$userId',
    );
  }
}
