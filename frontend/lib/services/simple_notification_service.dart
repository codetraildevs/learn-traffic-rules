import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleNotificationService {
  static final SimpleNotificationService _instance =
      SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();
      _isInitialized = true;
      debugPrint('✅ Simple notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing simple notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request notification permissions
    await Permission.notification.request();
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    // For now, just show a simple dialog or snackbar
    // This is a fallback when the main notification service fails
    debugPrint('📱 Simple Notification: $title - $body');
  }

  Future<void> showStudyReminderNotification({
    required String title,
    required String body,
    int studyGoalMinutes = 30,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'study_reminder:$studyGoalMinutes',
      id: 1,
    );
  }

  Future<void> showExamResultNotification({
    required String title,
    required String body,
    required bool passed,
    required int score,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'exam_result:$passed:$score',
      id: 2,
    );
  }

  Future<void> showPaymentNotification({
    required String title,
    required String body,
    required bool approved,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'payment:$approved',
      id: 3,
    );
  }

  Future<void> showAccessNotification({
    required String title,
    required String body,
    required String accessCode,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'access_granted:$accessCode',
      id: 4,
    );
  }

  Future<void> cancelNotification(int id) async {
    // Simple implementation - no actual cancellation needed
  }

  Future<void> cancelAllNotifications() async {
    // Simple implementation - no actual cancellation needed
  }

  Future<String?> getFCMToken() async {
    // Return a dummy token for now
    return 'dummy_token_123';
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint('📡 Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('📡 Unsubscribed from topic: $topic');
  }
}
