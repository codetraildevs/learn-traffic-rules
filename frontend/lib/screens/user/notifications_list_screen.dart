import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/simple_notification_service.dart';

class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends ConsumerState<NotificationsListScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final SimpleNotificationService _simpleNotificationService =
      SimpleNotificationService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _refreshTimer;
  final Set<String> _shownNotificationIds = {}; // Track shown notifications

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh notifications every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(refresh: true),
    );
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _notifications.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (response['success']) {
        final newNotifications = List<Map<String, dynamic>>.from(
          response['data']['notifications'] ?? [],
        );

        setState(() {
          if (refresh) {
            _notifications = newNotifications;
          } else {
            _notifications.addAll(newNotifications);
          }
          _currentPage++;
          _hasMore = newNotifications.length >= 20;
        });

        // Show push notifications for new unread notifications
        if (newNotifications.isNotEmpty) {
          _showPushNotificationsForNewNotifications(newNotifications);
        }
      } else {
        _showErrorSnackBar(
          response['message'] ?? 'Failed to load notifications',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await _apiService.markNotificationAsRead(notificationId);
      if (response['success']) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n['id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error marking notification as read: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showPushNotificationsForNewNotifications(
    List<Map<String, dynamic>> newNotifications,
  ) {
    // Show push notifications for unread notifications that haven't been shown yet
    for (final notification in newNotifications) {
      final isRead = notification['isRead'] ?? false;
      final notificationId = notification['id']?.toString() ?? '';

      if (!isRead && !_shownNotificationIds.contains(notificationId)) {
        debugPrint('🔔 Showing push notification for: $notificationId');
        _showPushNotification(notification);
        _shownNotificationIds.add(notificationId);
      }
    }
  }

  void _showPushNotification(Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? 'New Notification';
    final message = notification['message'] ?? '';

    debugPrint('🔔 Attempting to show push notification: $title ($type)');

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

          _notificationService.showStudyReminderNotification(
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

          _notificationService.showExamResultNotification(
            title: title,
            body: message,
            passed: type == 'EXAM_PASSED',
            score: score,
          );
          break;
        case 'PAYMENT_APPROVED':
        case 'PAYMENT_REJECTED':
          _notificationService.showPaymentNotification(
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

          _notificationService.showAccessNotification(
            title: title,
            body: message,
            accessCode: accessCode,
          );
          break;
        default:
          _notificationService.showLocalNotification(
            title: title,
            body: message,
            payload: notification['id']?.toString(),
          );
          break;
      }
      debugPrint('✅ Push notification sent successfully: $title');
    } catch (e) {
      // Fallback to simple notification service
      _simpleNotificationService.showLocalNotification(
        title: title,
        body: message,
        payload: notification['id']?.toString(),
      );
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'STUDY_REMINDER':
        return '📚';
      case 'EXAM_PASSED':
        return '🎉';
      case 'EXAM_FAILED':
        return '📖';
      case 'PAYMENT_APPROVED':
        return '💰';
      case 'PAYMENT_REJECTED':
        return '❌';
      case 'ACCESS_GRANTED':
        return '🔓';
      case 'NEW_EXAM':
        return '📝';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'STUDY_REMINDER':
        return AppColors.primary;
      case 'EXAM_PASSED':
        return AppColors.success;
      case 'EXAM_FAILED':
        return AppColors.warning;
      case 'PAYMENT_APPROVED':
        return AppColors.success;
      case 'PAYMENT_REJECTED':
        return AppColors.error;
      case 'ACCESS_GRANTED':
        return AppColors.success;
      case 'NEW_EXAM':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_notifications.any((n) => !n['isRead'])) {
    //   IconButton(
    //     onPressed: _markAllAsRead,
    //     icon: const Icon(Icons.done_all),
    //     color: Colors.black,
    //     tooltip: 'Mark all as read',
    //   );
    // }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No notifications yet',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'You\'ll see your notifications here',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _notifications.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final notification = _notifications[index];
                  final isRead = notification['isRead'] ?? false;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: isRead
                          ? AppColors.white
                          : AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.w),
                      leading: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(
                            notification['type'] ?? '',
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Center(
                          child: Text(
                            _getNotificationIcon(notification['type'] ?? ''),
                            style: TextStyle(fontSize: 20.sp),
                          ),
                        ),
                      ),
                      title: Text(
                        notification['title'] ?? '',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: isRead ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          Text(
                            notification['message'] ?? '',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(notification['createdAt']),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: isRead
                          ? null
                          : IconButton(
                              onPressed: () => _markAsRead(notification['id']),
                              icon: const Icon(Icons.check_circle_outline),
                              color: AppColors.primary,
                            ),
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(notification['id']);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  // void _testNotification() {
  //   try {
  //     NotificationPollingService().testNotification();
  //     _showSuccessSnackBar('Test notification sent!');
  //   } catch (e) {
  //     _showErrorSnackBar('Failed to send test notification: $e');
  //   }
  // }

  // Method to clear shown notifications (call this when user opens exams)
  void clearShownNotifications() {
    _shownNotificationIds.clear();
    debugPrint('🧹 Cleared shown notification tracking');
  }

  // Method to mark notification as shown without showing it again
  void markNotificationAsShown(String notificationId) {
    _shownNotificationIds.add(notificationId);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '$difference.inMinutes m ago';
      } else if (difference.inDays < 1) {
        return '$difference.inHours h ago';
      } else if (difference.inDays < 7) {
        return '$difference.inDays d ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
