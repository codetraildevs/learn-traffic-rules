import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request local notification permissions
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: $response');
    // Handle local notification tap
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'learn_traffic_rules_channel',
          'Learn Traffic Rules Notifications',
          channelDescription: 'Notifications for the Learn Traffic Rules app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
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
      id: 1, // Use ID 1 for study reminders
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
      id: 2, // Use ID 2 for exam results
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
      id: 3, // Use ID 3 for payment notifications
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
      id: 4, // Use ID 4 for access notifications
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Placeholder methods for Firebase functionality (can be implemented later)
  Future<String?> getFCMToken() async {
    // Return null for now since Firebase is disabled
    return null;
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint(
      '📡 Topic subscription disabled (Firebase not available): $topic',
    );
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint(
      '📡 Topic unsubscription disabled (Firebase not available): $topic',
    );
  }
}
