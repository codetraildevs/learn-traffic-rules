import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: [
            Tab(text: l10n.notifications),
            Tab(text: l10n.settings),
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
                        l10n.notificationSettings,
                        style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.customizeNotificationPreferences,
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
                        l10n.notificationTypes,
                        style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                      ),
                      SizedBox(height: 20.h),

                      _buildNotificationOption(
                        l10n.examReminders,
                        l10n.getNotifiedAboutUpcomingExams,
                        Icons.quiz,
                        _examReminders,
                        (value) => setState(() => _examReminders = value),
                      ),

                      _buildNotificationOption(
                        l10n.achievementAlerts,
                        l10n.celebrateProgressAndAchievements,
                        Icons.emoji_events,
                        _achievementAlerts,
                        (value) => setState(() => _achievementAlerts = value),
                      ),

                      _buildNotificationOption(
                        l10n.studyReminders,
                        l10n.dailyRemindersToKeepUp,
                        Icons.schedule,
                        _studyReminders,
                        (value) => setState(() => _studyReminders = value),
                      ),

                      _buildNotificationOption(
                        l10n.systemUpdates,
                        l10n.importantAppUpdatesAndMaintenance,
                        Icons.system_update,
                        _systemUpdates,
                        (value) => setState(() => _systemUpdates = value),
                      ),

                      _buildNotificationOption(
                        l10n.paymentNotifications,
                        l10n.updatesAboutPaymentsAndAccessCodes,
                        Icons.payment,
                        _paymentNotifications,
                        (value) =>
                            setState(() => _paymentNotifications = value),
                      ),

                      _buildNotificationOption(
                        l10n.weeklyReports,
                        l10n.summaryOfWeeklyProgressAndPerformance,
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
                        l10n.notificationTiming,
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
                              l10n.quietHours,
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
                              l10n.vibration,
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

                SizedBox(height: 8.h),

                // Save Button
                CustomButton(
                  text: l10n.savePreferences,
                  onPressed: _isLoading ? null : _savePreferences,
                  backgroundColor: AppColors.primary,
                  width: double.infinity,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 32.h),
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
    final l10n = AppLocalizations.of(context);
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
            SnackBar(
              content: Text(l10n.notificationPreferencesSavedSuccessfully),
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
            content: Text('${l10n.failedToSavePreferences}: $e'),
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
}
