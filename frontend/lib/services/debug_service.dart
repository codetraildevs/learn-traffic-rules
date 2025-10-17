import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DebugService {
  static const String _tag = 'TrafficRulesApp';

  /// Log authentication events with detailed information
  static void logAuthEvent(String event, Map<String, dynamic> data) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'AUTH_EVENT: $event',
        name: _tag,
        time: DateTime.now(),
        level: 800, // INFO level
        error: null,
        stackTrace: null,
        zone: null,
      );

      // Print detailed data for debugging
      debugPrint('🔐 AUTH DEBUG [$timestamp]: $event');
      debugPrint('📊 Data: $data');
    }
  }

  /// Log API calls with request/response details
  static void logApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? requestData,
    int? statusCode,
    String? response,
    String? error,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'API_CALL: $method $endpoint',
        name: _tag,
        time: DateTime.now(),
        level: 700, // FINE level
        error: error != null ? Exception(error) : null,
        stackTrace: null,
        zone: null,
      );

      debugPrint('🌐 API DEBUG [$timestamp]: $method $endpoint');
      if (requestData != null) debugPrint('📤 Request: $requestData');
      if (statusCode != null) debugPrint('📥 Status: $statusCode');
      if (response != null) debugPrint('📥 Response: $response');
      if (error != null) debugPrint('❌ Error: $error');
    }
  }

  /// Log device information
  static void logDeviceInfo(Map<String, dynamic> deviceInfo) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'DEVICE_INFO: Device detected',
        name: _tag,
        time: DateTime.now(),
        level: 800,
        error: null,
        stackTrace: null,
        zone: null,
      );

      debugPrint('📱 DEVICE DEBUG [$timestamp]:');
      deviceInfo.forEach((key, value) {
        debugPrint('   $key: $value');
      });
    }
  }

  /// Log form validation
  static void logFormValidation(
    String formName,
    Map<String, dynamic> validationResults,
  ) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'FORM_VALIDATION: $formName',
        name: _tag,
        time: DateTime.now(),
        level: 600, // FINE level
        error: null,
        stackTrace: null,
        zone: null,
      );

      debugPrint('📝 FORM DEBUG [$timestamp]: $formName');
      validationResults.forEach((field, result) {
        final status = result['valid'] == true ? '✅' : '❌';
        debugPrint('   $status $field: $result');
      });
    }
  }

  /// Log user actions
  static void logUserAction(String action, Map<String, dynamic>? context) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'USER_ACTION: $action',
        name: _tag,
        time: DateTime.now(),
        level: 800,
        error: null,
        stackTrace: null,
        zone: null,
      );

      debugPrint('👤 USER DEBUG [$timestamp]: $action');
      if (context != null) {
        context.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      }
    }
  }

  /// Log errors with stack trace
  static void logError(
    String error,
    dynamic exception,
    StackTrace? stackTrace,
  ) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'ERROR: $error',
        name: _tag,
        time: DateTime.now(),
        level: 1000, // SEVERE level
        error: exception,
        stackTrace: stackTrace,
        zone: null,
      );

      debugPrint('💥 ERROR DEBUG [$timestamp]: $error');
      debugPrint('Exception: $exception');
      if (stackTrace != null) {
        debugPrint('Stack Trace: $stackTrace');
      }
    }
  }

  /// Log network connectivity
  static void logNetworkStatus(String status, String? details) {
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        'NETWORK: $status',
        name: _tag,
        time: DateTime.now(),
        level: 800,
        error: null,
        stackTrace: null,
        zone: null,
      );

      debugPrint('🌐 NETWORK DEBUG [$timestamp]: $status');
      if (details != null) debugPrint('   Details: $details');
    }
  }
}
