import 'package:flutter/foundation.dart';

class ErrorHandlerService {
  /// Converts technical errors into user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Network/Connection errors
    if (errorString.contains('connection timed out') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no internet connection')) {
      return '🌐 Connection Error\n\nPlease check your internet connection and try again. Make sure you have a stable network connection.';
    }

    if (errorString.contains('socketexception') ||
        errorString.contains('handshake exception') ||
        errorString.contains('certificate verify failed')) {
      return '🔌 Network Error\n\nUnable to connect to the server. Please check your internet connection and try again.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return '⚠️ Server Error\n\nThe server is temporarily unavailable. Please try again in a few minutes.';
    }

    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return '🚫 Service Unavailable\n\nThe service is temporarily down for maintenance. Please try again later.';
    }

    if (errorString.contains('502') || errorString.contains('bad gateway')) {
      return '🔄 Server Error\n\nThe server is experiencing issues. Please try again in a moment.';
    }

    // Authentication errors
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return '🔐 Authentication Error\n\nInvalid credentials. Please check your username and password.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return '🚫 Access Denied\n\nYou don\'t have permission to access this resource.';
    }

    if (errorString.contains('device not registered') ||
        errorString.contains('device binding')) {
      return '📱 Device Security\n\nThis device is not registered. Please contact support for assistance.';
    }

    // Validation errors
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return '✏️ Invalid Input\n\nPlease check your information and try again.';
    }

    if (errorString.contains('password') && errorString.contains('weak')) {
      return '🔒 Weak Password\n\nPlease choose a stronger password with at least 8 characters.';
    }

    if (errorString.contains('phone number') &&
        errorString.contains('invalid')) {
      return '📞 Invalid Phone Number\n\nPlease enter a valid phone number.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return '⏱️ Request Timeout\n\nThe request took too long to complete. Please check your connection and try again.';
    }

    // Rate limit errors
    if (errorString.contains('429') || 
        errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return '🚫 Rate Limit Exceeded\n\nYou\'re making requests too quickly. Please wait a moment before trying again.';
    }

    // API errors
    if (errorString.contains('apiexception')) {
      return '🔧 API Error\n\nThere was a problem with the server. Please try again.';
    }

    // Generic fallback
    return '❌ Error\n\nSomething went wrong. Please try again or contact support if the problem persists.';
  }

  /// Gets a short error message for snackbars
  static String getShortErrorMessage(dynamic error) {
    if (error == null) return 'An error occurred';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection timed out') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable')) {
      return 'No internet connection';
    }

    if (errorString.contains('socketexception')) {
      return 'Network error';
    }

    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return 'Server error';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Invalid credentials';
    }

    if (errorString.contains('device not registered')) {
      return 'Device not registered';
    }

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timeout';
    }

    if (errorString.contains('429') || 
        errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return 'Too many requests';
    }

    return 'Something went wrong';
  }

  /// Gets an appropriate icon for the error type
  static String getErrorIcon(dynamic error) {
    if (error == null) return '❌';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection') || errorString.contains('network')) {
      return '🌐';
    }

    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503')) {
      return '⚠️';
    }

    if (errorString.contains('auth') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return '🔐';
    }

    if (errorString.contains('device')) {
      return '📱';
    }

    if (errorString.contains('timeout')) {
      return '⏱️';
    }

    if (errorString.contains('429') || 
        errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return '🚫';
    }

    return '❌';
  }

  /// Logs error details for debugging
  static void logError(
    String context,
    dynamic error, {
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('🚨 ERROR in $context:');
      debugPrint('   Error: $error');
      if (additionalData != null) {
        debugPrint('   Additional Data: $additionalData');
      }
      //debugPrint('   Stack Trace: $stackTrace');
    }
  }
}
