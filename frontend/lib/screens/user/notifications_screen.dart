import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
//import '../../services/notification_service.dart';
//import '../../services/simple_notification_service.dart';
import 'notifications_list_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  // final NotificationService _notificationService = NotificationService();
  // final SimpleNotificationService _simpleNotificationService =
  //    SimpleNotificationService();
  late TabController _tabController;
  bool _isLoading = false;
  bool _examReminders = true;
  bool _achievementAlerts = true;
  bool _studyReminders = true;
  bool _systemUpdates = true;
  bool _paymentNotifications = true;
  bool _weeklyReports = false;
  bool _quietHoursEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: const [],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notifications List Tab
          const NotificationsListScreen(),
          // Settings Tab
          SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 48.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Notification Settings',
                        style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Customize your notification preferences',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Notification Categories
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Types',
                        style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                      ),
                      SizedBox(height: 20.h),

                      _buildNotificationOption(
                        'Exam Reminders',
                        'Get notified about upcoming exams and deadlines',
                        Icons.quiz,
                        _examReminders,
                        (value) => setState(() => _examReminders = value),
                      ),

                      _buildNotificationOption(
                        'Achievement Alerts',
                        'Celebrate your progress and achievements',
                        Icons.emoji_events,
                        _achievementAlerts,
                        (value) => setState(() => _achievementAlerts = value),
                      ),

                      _buildNotificationOption(
                        'Study Reminders',
                        'Daily reminders to keep up with your studies',
                        Icons.schedule,
                        _studyReminders,
                        (value) => setState(() => _studyReminders = value),
                      ),

                      _buildNotificationOption(
                        'System Updates',
                        'Important app updates and maintenance notices',
                        Icons.system_update,
                        _systemUpdates,
                        (value) => setState(() => _systemUpdates = value),
                      ),

                      _buildNotificationOption(
                        'Payment Notifications',
                        'Updates about payments and access codes',
                        Icons.payment,
                        _paymentNotifications,
                        (value) =>
                            setState(() => _paymentNotifications = value),
                      ),

                      _buildNotificationOption(
                        'Weekly Reports',
                        'Summary of your weekly progress and performance',
                        Icons.analytics,
                        _weeklyReports,
                        (value) => setState(() => _weeklyReports = value),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Notification Timing
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Timing',
                        style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                      ),
                      SizedBox(height: 16.h),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Quiet Hours: 10:00 PM - 7:00 AM',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                          Switch(
                            value: _quietHoursEnabled,
                            onChanged: (value) {
                              setState(() {
                                _quietHoursEnabled = value;
                              });
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      Row(
                        children: [
                          Icon(
                            Icons.vibration,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Vibration',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                          Switch(
                            value: _vibrationEnabled,
                            onChanged: (value) {
                              setState(() {
                                _vibrationEnabled = value;
                              });
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Test Notification Buttons
                // CustomButton(
                //   text: 'Test Push Notification',
                //   onPressed: _testPushNotification,
                //   backgroundColor: AppColors.secondary,
                //   width: double.infinity,
                // ),

                // SizedBox(height: 12.h),

                // CustomButton(
                //   text: 'Test Study Reminder',
                //   onPressed: _testStudyReminder,
                //   backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                //   width: double.infinity,
                // ),

                // SizedBox(height: 12.h),

                // CustomButton(
                //   text: 'Test Simple Notification',
                //   onPressed: _testSimpleNotification,
                //   backgroundColor: AppColors.grey600,
                //   width: double.infinity,
                // ),
                SizedBox(height: 8.h),

                // Save Button
                CustomButton(
                  text: 'Save Preferences',
                  onPressed: _isLoading ? null : _savePreferences,
                  backgroundColor: AppColors.primary,
                  width: double.infinity,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreferences() async {
    try {
      final response = await _apiService.getNotificationPreferences();
      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _examReminders = data['examReminders'] ?? true;
          _achievementAlerts = data['achievementNotifications'] ?? true;
          _studyReminders = data['studyReminders'] ?? true;
          _systemUpdates = data['systemAnnouncements'] ?? true;
          _paymentNotifications = data['paymentUpdates'] ?? true;
          _weeklyReports = data['weeklyReports'] ?? false;
          _quietHoursEnabled = data['quietHoursEnabled'] ?? true;
          _vibrationEnabled = data['vibrationEnabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = {
        'examReminders': _examReminders,
        'achievementNotifications': _achievementAlerts,
        'studyReminders': _studyReminders,
        'systemAnnouncements': _systemUpdates,
        'paymentUpdates': _paymentNotifications,
        'weeklyReports': _weeklyReports,
        'quietHoursEnabled': _quietHoursEnabled,
        'vibrationEnabled': _vibrationEnabled,
      };

      final response = await _apiService.updateNotificationPreferences(
        preferences,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to save preferences');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // void _testPushNotification() {
  //   try {
  //     _notificationService.showStudyReminderNotification(
  //       title: 'Test Study Reminder! 📚',
  //       body:
  //           'This is a test push notification to verify the system is working.',
  //       studyGoalMinutes: 30,
  //     );
  //   } catch (e) {
  //     // Fallback to simple notification service
  //     _simpleNotificationService.showStudyReminderNotification(
  //       title: 'Test Study Reminder! 📚',
  //       body:
  //           'This is a test push notification to verify the system is working.',
  //       studyGoalMinutes: 30,
  //     );
  //   }
  // }

  // void _testStudyReminder() {
  //   try {
  //     NotificationPollingService().testStudyReminder();
  //   } catch (e) {
  //     debugPrint('Error testing study reminder: $e');
  //   }
  // }

  // void _testSimpleNotification() {
  //   try {
  //     NotificationPollingService().testNotification();
  //   } catch (e) {
  //     debugPrint('Error testing simple notification: $e');
  //   }
  // }
}
