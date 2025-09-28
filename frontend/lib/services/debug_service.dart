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
      print('🔐 AUTH DEBUG [$timestamp]: $event');
      print('📊 Data: $data');
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

      print('🌐 API DEBUG [$timestamp]: $method $endpoint');
      if (requestData != null) print('📤 Request: $requestData');
      if (statusCode != null) print('📥 Status: $statusCode');
      if (response != null) print('📥 Response: $response');
      if (error != null) print('❌ Error: $error');
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

      print('📱 DEVICE DEBUG [$timestamp]:');
      deviceInfo.forEach((key, value) {
        print('   $key: $value');
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

      print('📝 FORM DEBUG [$timestamp]: $formName');
      validationResults.forEach((field, result) {
        final status = result['valid'] == true ? '✅' : '❌';
        print('   $status $field: ${result['message']}');
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

      print('👤 USER DEBUG [$timestamp]: $action');
      if (context != null) {
        context.forEach((key, value) {
          print('   $key: $value');
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

      print('💥 ERROR DEBUG [$timestamp]: $error');
      print('Exception: $exception');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
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

      print('🌐 NETWORK DEBUG [$timestamp]: $status');
      if (details != null) print('   Details: $details');
    }
  }
}
