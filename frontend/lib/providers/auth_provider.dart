import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(status: AuthStatus.initial)) {
    _checkAuthStatus();
  }

  final ApiService _apiService = ApiService();

  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      // Check if user has valid token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      if (token != null) {
        // Token exists, try to get user data
        // In a real app, you might want to validate the token with the server
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: null, // You would fetch user data here
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<bool> login(LoginRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.login(request);

      if (response.success && response.data != null) {
        await _apiService.setAuthTokens(
          response.data!.token,
          response.data!.refreshToken,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data!.user,
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
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.register(request);

      if (response.success && response.data != null) {
        await _apiService.setAuthTokens(
          response.data!.token,
          response.data!.refreshToken,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data!.user,
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
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Log error but continue with logout
      debugPrint('Logout error: $e');
    } finally {
      await _apiService.clearAuthTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        error: null,
      );
    }
  }

  Future<bool> forgotPassword(ForgotPasswordRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.forgotPassword(request);

      state = state.copyWith(isLoading: false);
      return response['success'] == true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.resetPassword(request);

      state = state.copyWith(isLoading: false);
      return response['success'] == true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> deleteAccount(DeleteAccountRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteAccount(request);

      if (response['success'] == true) {
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
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
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
