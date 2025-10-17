import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'simple_notification_service.dart';

class NotificationPollingService {
  static final NotificationPollingService _instance =
      NotificationPollingService._internal();
  factory NotificationPollingService() => _instance;
  NotificationPollingService._internal();

  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final SimpleNotificationService _simpleNotificationService =
      SimpleNotificationService();

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _lastNotificationId;
  int _pollingIntervalSeconds = 30; // Check every 30 seconds
  final Set<String> _shownNotificationIds = {}; // Track shown notifications

  Future<void> startPolling() async {
    if (_isPolling) return;

    _isPolling = true;
    debugPrint('🔄 Starting notification polling service...');

    // Initial check
    await _checkForNewNotifications();

    // Set up periodic polling
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingIntervalSeconds),
      (_) => _checkForNewNotifications(),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Notification polling service stopped');
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final response = await _apiService.getNotifications(
        page: 1,
        limit: 5, // Only check the latest 5 notifications
      );

      if (response['success']) {
        final notifications = List<Map<String, dynamic>>.from(
          response['data']['notifications'] ?? [],
        );

        if (notifications.isNotEmpty) {
          final latestNotification = notifications.first;
          final latestId = latestNotification['id']?.toString();

          // Check if this is a new notification
          if (_lastNotificationId != null && latestId != _lastNotificationId) {
            // Show push notification for the new notification
            await _showPushNotification(latestNotification);
          }

          _lastNotificationId = latestId;
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for new notifications: $e');
    }
  }

  Future<void> _showPushNotification(Map<String, dynamic> notification) async {
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? 'New Notification';
    final message = notification['message'] ?? '';
    final isRead = notification['isRead'] ?? false;
    final notificationId = notification['id']?.toString() ?? '';

    // Only show push notification for unread notifications that haven't been shown
    if (isRead || _shownNotificationIds.contains(notificationId)) return;

    debugPrint('🔔 Showing push notification: $title');
    _shownNotificationIds.add(notificationId);

    try {
      switch (type) {
        case 'STUDY_REMINDER':
          int studyGoalMinutes = 30;
          try {
            if (notification['data'] is String) {
              final dataMap = Map<String, dynamic>.from(
                jsonDecode(notification['data'] as String),
              );
              studyGoalMinutes = dataMap['studyGoalMinutes'] ?? 30;
            } else if (notification['data'] is Map) {
              studyGoalMinutes =
                  notification['data']?['studyGoalMinutes'] ?? 30;
            }
          } catch (e) {
            debugPrint('Error parsing study goal minutes: $e');
          }

          await _notificationService.showStudyReminderNotification(
            title: title,
            body: message,
            studyGoalMinutes: studyGoalMinutes,
          );
          break;
        case 'EXAM_PASSED':
        case 'EXAM_FAILED':
          int score = 0;
          try {
            if (notification['data'] is String) {
              final dataMap = Map<String, dynamic>.from(
                jsonDecode(notification['data'] as String),
              );
              score = dataMap['score'] ?? 0;
            } else if (notification['data'] is Map) {
              score = notification['data']?['score'] ?? 0;
            }
          } catch (e) {
            debugPrint('Error parsing exam score: $e');
          }

          await _notificationService.showExamResultNotification(
            title: title,
            body: message,
            passed: type == 'EXAM_PASSED',
            score: score,
          );
          break;
        case 'PAYMENT_APPROVED':
        case 'PAYMENT_REJECTED':
          await _notificationService.showPaymentNotification(
            title: title,
            body: message,
            approved: type == 'PAYMENT_APPROVED',
          );
          break;
        case 'ACCESS_GRANTED':
          String accessCode = '';
          try {
            if (notification['data'] is String) {
              final dataMap = Map<String, dynamic>.from(
                jsonDecode(notification['data'] as String),
              );
              accessCode = dataMap['accessCodeId'] ?? '';
            } else if (notification['data'] is Map) {
              accessCode = notification['data']?['accessCodeId'] ?? '';
            }
          } catch (e) {
            debugPrint('Error parsing access code: $e');
          }

          await _notificationService.showAccessNotification(
            title: title,
            body: message,
            accessCode: accessCode,
          );
          break;
        default:
          await _notificationService.showLocalNotification(
            title: title,
            body: message,
            payload: notification['id']?.toString(),
          );
          break;
      }
    } catch (e) {
      debugPrint('❌ Error showing push notification: $e');
      // Fallback to simple notification service
      try {
        await _simpleNotificationService.showLocalNotification(
          title: title,
          body: message,
        );
      } catch (fallbackError) {
        debugPrint('❌ Fallback notification also failed: $fallbackError');
      }
    }
  }

  // Test method to manually trigger a notification
  Future<void> testNotification() async {
    await _notificationService.showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from the app!',
      payload: 'test',
    );
  }

  // Test method to trigger a study reminder notification
  Future<void> testStudyReminder() async {
    await _notificationService.showStudyReminderNotification(
      title: 'Study Reminder',
      body: 'Time to study traffic rules! Your goal is 30 minutes today.',
      studyGoalMinutes: 30,
    );
  }

  void setPollingInterval(int seconds) {
    _pollingIntervalSeconds = seconds;
    if (_isPolling) {
      stopPolling();
      startPolling();
    }
  }

  // Clear shown notifications (call when user opens exams)
  void clearShownNotifications() {
    _shownNotificationIds.clear();
    debugPrint('🧹 Cleared shown notification tracking');
  }

  // Mark notification as shown without showing it
  void markNotificationAsShown(String notificationId) {
    _shownNotificationIds.add(notificationId);
  }

  bool get isPolling => _isPolling;
}
