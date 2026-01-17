import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/error_handler_service.dart';
import '../services/device_service.dart';
import '../services/network_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;
  final AccessPeriod? accessPeriod;

  AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
    this.accessPeriod,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    AccessPeriod? accessPeriod,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      accessPeriod: accessPeriod ?? this.accessPeriod,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(status: AuthStatus.initial)) {
    _initialize();
  }

  final ApiService _apiService = ApiService();

  Future<void> _initialize() async {
    await _apiService.initialize();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      debugPrint('🔄 AUTH RESTORE: Starting session restoration...');

      // Check if user has valid token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userJson = prefs.getString(AppConstants.userKey);
      final accessPeriodJson = prefs.getString('access_period');

      debugPrint('🔄 AUTH RESTORE: Stored data check:');
      debugPrint('   Token exists: $token');
      debugPrint('   User data exists: $userJson');
      debugPrint('   Access period exists: $accessPeriodJson');

      if (token != null && userJson != null) {
        try {
          // Parse stored user data
          final userData = json.decode(userJson);
          final user = User.fromJson(userData);

          // Load stored access period
          AccessPeriod? accessPeriod;
          final accessPeriodJson = prefs.getString('access_period');
          if (accessPeriodJson != null) {
            try {
              final accessPeriodData = json.decode(accessPeriodJson);
              accessPeriod = AccessPeriod.fromJson(accessPeriodData);
              debugPrint(
                '🔄 AUTH RESTORE: Access period loaded - $accessPeriod days left',
              );
            } catch (e) {
              debugPrint('❌ AUTH RESTORE: Failed to parse access period: $e');
            }
          }

          debugPrint('🔄 AUTH RESTORE: Restoring user session');
          debugPrint('   User: $user ($user.role)');
          debugPrint('   Token exists: $token');
          debugPrint(
            '   Access period: $accessPeriod ($accessPeriod.remainingDays days)',
          );

          // Check internet connection before making API calls
          final networkService = NetworkService();
          final hasInternet = await networkService.hasInternetConnection();

          if (!hasInternet) {
            debugPrint(
              '🌐 AUTH RESTORE: No internet connection, using stored data',
            );
            // No internet - use stored data and restore session
            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              accessPeriod: accessPeriod,
              isLoading: false,
            );
            return;
          }

          // For users, always fetch fresh access period data during session restoration (only if online)
          if (user.role == 'USER') {
            debugPrint(
              '🔄 AUTH RESTORE: Fetching fresh access period for user...',
            );
            try {
              // Make a fresh login call to get the latest access period
              final loginRequest = LoginRequest(
                phoneNumber: user.phoneNumber,
                deviceId: user.deviceId,
              );
              final freshResponse = await _apiService.login(loginRequest);

              if (freshResponse.success == true && freshResponse.data != null) {
                final freshAccessPeriod = freshResponse.data!.accessPeriod;
                debugPrint(
                  '🔄 AUTH RESTORE: Fresh access period loaded - $freshAccessPeriod days left',
                );

                // Store the fresh access period
                await _storeUserData(user, accessPeriod: freshAccessPeriod);

                state = state.copyWith(
                  status: AuthStatus.authenticated,
                  user: user,
                  accessPeriod: freshAccessPeriod,
                  isLoading: false,
                );
                return;
              }
            } catch (e) {
              debugPrint(
                '❌ AUTH RESTORE: Failed to fetch fresh access period: $e',
              );
              // Fall back to stored data - don't clear session if offline
              debugPrint('🔄 AUTH RESTORE: Using stored data due to error');
              state = state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
                accessPeriod: accessPeriod,
                isLoading: false,
              );
              return;
            }
          }

          // Validate token by making a test API call (only if online)
          await _validateTokenAndRestoreUser(
            user,
            token,
            accessPeriod: accessPeriod,
          );
        } catch (e) {
          debugPrint('❌ AUTH RESTORE: Failed to parse user data: $e');
          // Clear invalid data
          await _clearStoredAuth();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      } else {
        debugPrint('🔄 AUTH RESTORE: No stored auth data found');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('❌ AUTH RESTORE: Error checking auth status: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> _validateTokenAndRestoreUser(
    User user,
    String token, {
    AccessPeriod? accessPeriod,
  }) async {
    try {
      // Check internet before validating token
      final networkService = NetworkService();
      final hasInternet = await networkService.hasInternetConnection();

      if (!hasInternet) {
        debugPrint(
          '🌐 AUTH RESTORE: No internet, skipping token validation, using stored data',
        );
        // No internet - restore with stored data
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          accessPeriod: accessPeriod,
          isLoading: false,
        );
        return;
      }

      // Make a simple API call to validate the token
      // We'll use the getExams call as it requires authentication
      await _apiService.getExams();

      debugPrint('✅ AUTH RESTORE: Token validated successfully');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        accessPeriod: accessPeriod,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ AUTH RESTORE: Token validation failed: $e');

      // Check if error is due to network issues
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('socketexception') ||
          errorString.contains('no internet');

      if (isNetworkError) {
        debugPrint(
          '🌐 AUTH RESTORE: Network error detected, using stored data',
        );
        // Network error - restore with stored data instead of clearing
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          accessPeriod: accessPeriod,
          isLoading: false,
        );
      } else {
        // Other errors - token might be invalid
        debugPrint('❌ AUTH RESTORE: Non-network error, clearing auth');
        await _clearStoredAuth();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove('access_period');
    await _apiService.clearAuthTokens();
  }

  Future<void> _storeUserData(User user, {AccessPeriod? accessPeriod}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(AppConstants.userKey, userJson);

      if (accessPeriod != null) {
        final accessPeriodJson = json.encode(accessPeriod.toJson());
        await prefs.setString('access_period', accessPeriodJson);
        debugPrint(
          '💾 AUTH STORE: User data and access period stored successfully',
        );
        debugPrint(
          '💾 AUTH STORE: Access period - hasAccess: $accessPeriod.hasAccess, remainingDays: $accessPeriod.remainingDays',
        );
      } else {
        debugPrint(
          '💾 AUTH STORE: User data stored successfully (no access period)',
        );
      }
    } catch (e) {
      debugPrint('❌ AUTH STORE: Failed to store user data: $e');
    }
  }

  Future<bool> login(LoginRequest request) async {
    try {
      // Don't change auth state during login to prevent auto-refresh
      // state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.login(request);

      // Debug logging to see the actual response
      debugPrint('🔍 LOGIN RESPONSE DEBUG:');
      debugPrint('   success: $response.success (type: $response.data)');
      // debugPrint('   message: $\1');
      // debugPrint('   data: $\1');
      // debugPrint('   accessPeriod: $\1');
      // debugPrint(
      //   '   accessPeriod hasAccess: $\1',
      // );
      // debugPrint(
      //   '   accessPeriod remainingDays: $\1',
      // );

      // More robust null checking
      final isSuccess = response.success == true;
      final hasData = response.data != null;

      debugPrint('   isSuccess: $isSuccess, hasData: $hasData');

      if (isSuccess && hasData) {
        await _apiService.setAuthTokens(
          response.data!.token,
          response.data!.refreshToken,
        );

        // Store user data for session restoration
        await _storeUserData(
          response.data!.user,
          accessPeriod: response.data!.accessPeriod,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data!.user,
          accessPeriod: response.data!.accessPeriod,
          isLoading: false,
        );
        return true;
      } else {
        debugPrint('❌ LOGIN FAILED: ${response.message}');
        // Don't change auth state on failure to prevent refresh
        return false;
      }
    } catch (e) {
      // Log error for debugging
      ErrorHandlerService.logError(
        'Login',
        e,
        additionalData: {
          'deviceId': request.deviceId,
          'hasPhoneNumber': request.phoneNumber.isNotEmpty,
        },
      );

      // Get user-friendly error message with context
      final userFriendlyError = ErrorHandlerService.getErrorMessage(
        e,
        context: 'login',
      );

      debugPrint('❌ LOGIN ERROR: $userFriendlyError');

      // Set error in auth state so login screen can display it
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: userFriendlyError,
        isLoading: false,
      );

      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.register(request);

      // Debug logging to see the actual response
      // debugPrint('🔍 REGISTER RESPONSE DEBUG:');
      // debugPrint(
      //   '   success: $\1 (type: $\1)',
      // );
      // debugPrint('   message: $\1');
      // debugPrint('   data: $\1');

      // More robust null checking
      final isSuccess = response.success == true;
      final hasData = response.data != null;

      debugPrint('   isSuccess: $isSuccess, hasData: $hasData');

      if (isSuccess && hasData) {
        await _apiService.setAuthTokens(
          response.data!.token,
          response.data!.refreshToken,
        );

        // Store user data for session restoration
        await _storeUserData(
          response.data!.user,
          accessPeriod: response.data!.accessPeriod,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data!.user,
          accessPeriod: response.data!.accessPeriod,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: response.message,
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      // Log error for debugging
      ErrorHandlerService.logError(
        'Register',
        e,
        additionalData: {
          'deviceId': request.deviceId,
          'fullName': request.fullName,
          'phoneNumber': request.phoneNumber,
          'role': request.role,
        },
      );

      // Get user-friendly error message with context
      final userFriendlyError = ErrorHandlerService.getErrorMessage(
        e,
        context: 'register',
      );

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: userFriendlyError,
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    // OPTIMIZATION: Clear local state FIRST for instant logout
    // Then call API in background (non-blocking)
    
    // Step 1: Clear local state immediately (instant)
    await _clearStoredAuth();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      error: null,
    );
    
    // Step 2: Call API logout in background (non-blocking, fire and forget)
    _logoutOnServer().catchError((e) {
      debugPrint('⚠️ Background logout API call failed: $e');
      // Ignore errors - local logout already completed
    });
  }
  
  /// Logout on server (runs in background, non-blocking)
  Future<void> _logoutOnServer() async {
    try {
      // Get device ID for logout
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceId();

      final networkService = NetworkService();
      final hasInternet = await networkService.hasInternetConnection();

      if (hasInternet) {
        // Call API with shorter timeout since it's background
        await _apiService.logout(deviceId).timeout(const Duration(seconds: 3));
        debugPrint('✅ Background logout API call succeeded');
      } else {
        debugPrint(
          '🌐 LOGOUT: No internet connection, local logout already completed',
        );
      }
    } on TimeoutException catch (_) {
      debugPrint(
        '⏱️ LOGOUT: Server did not respond, local logout already completed',
      );
    } catch (e) {
      // Log error but don't throw - local logout already completed
      debugPrint('⚠️ Background logout error: $e');
    }
  }

  Future<bool> forgotPassword(ForgotPasswordRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.forgotPassword(request);

      state = state.copyWith(isLoading: false);
      return (response['success'] as bool?) ?? false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.resetPassword(request);

      state = state.copyWith(isLoading: false);
      return (response['success'] as bool?) ?? false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteAccount(DeleteAccountRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteAccount(request.phoneNumber);

      if ((response['success'] as bool?) ?? false) {
        await logout();
        return true;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Failed to delete account',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh access period from server (useful when admin grants access)
  /// This should be called when app comes to foreground or when user navigates to exams
  Future<void> refreshAccessPeriod() async {
    try {
      final currentUser = state.user;
      if (currentUser == null || currentUser.role != 'USER') {
        debugPrint('🔄 REFRESH ACCESS: Not a user, skipping refresh');
        return;
      }

      // Check internet connection
      final networkService = NetworkService();
      final hasInternet = await networkService.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('🔄 REFRESH ACCESS: No internet, skipping refresh');
        return;
      }

      debugPrint('🔄 REFRESH ACCESS: Refreshing access period for user...');
      
      // Make a fresh login call to get the latest access period
      final loginRequest = LoginRequest(
        phoneNumber: currentUser.phoneNumber,
        deviceId: currentUser.deviceId,
      );
      final freshResponse = await _apiService.login(loginRequest);

      if (freshResponse.success == true && freshResponse.data != null) {
        final freshAccessPeriod = freshResponse.data!.accessPeriod;
        debugPrint(
          '🔄 REFRESH ACCESS: Fresh access period loaded - hasAccess: ${freshAccessPeriod?.hasAccess}, remainingDays: ${freshAccessPeriod?.remainingDays}',
        );

        // Store the fresh access period
        await _storeUserData(currentUser, accessPeriod: freshAccessPeriod);

        // Update state with fresh access period
        state = state.copyWith(
          accessPeriod: freshAccessPeriod,
        );
        
        debugPrint('✅ REFRESH ACCESS: Access period refreshed successfully');
      } else {
        debugPrint('❌ REFRESH ACCESS: Failed to refresh access period');
      }
    } catch (e) {
      debugPrint('❌ REFRESH ACCESS: Error refreshing access period: $e');
      // Don't throw error, just log it - user can continue with cached data
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience providers
final userProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
