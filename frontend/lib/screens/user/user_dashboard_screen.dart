import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/models/user_management_model.dart';
import 'package:learn_traffic_rules/services/user_management_service.dart';
import 'package:learn_traffic_rules/widgets/loading_widget.dart';
import 'package:learn_traffic_rules/l10n/app_localizations.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  RemainingDaysData? _remainingDaysData;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRemainingDays();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    // Refresh every 24 hours (86400000 milliseconds)
    _refreshTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      if (mounted) {
        _loadRemainingDays();
      }
    });
  }

  Future<void> _loadRemainingDays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Loading remaining days...');
      final response = await _userManagementService.getMyRemainingDays();
      debugPrint('🔄 Remaining days response: $response');

      if (response.success) {
        setState(() {
          _remainingDaysData = response.data;
        });
      } else {
        debugPrint('❌ Failed to load remaining days: $_remainingDaysData');
        _showErrorSnackBar(
          'Failed to load remaining days: $_remainingDaysData',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading remaining days: $e');
      _showErrorSnackBar('Error loading remaining days: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.myDashboard, style: AppTextStyles.heading2),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRemainingDays,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _remainingDaysData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.errorLoadingDashboard,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadRemainingDays,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: AppColors.white,
                                  size: 32.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome Back!',
                                        style: AppTextStyles.heading2.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Track your access and progress',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Access Status Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.vpn_key,
                                color: AppColors.primary,
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Access Status',
                                style: AppTextStyles.heading3.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          if (_remainingDaysData!.hasActiveAccess) ...[
                            // Active Access
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Active Access',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'You have $_remainingDaysData days remaining',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                  if (_remainingDaysData!.activeCodesCount > 1)
                                    Text(
                                      '${_remainingDaysData!.activeCodesCount} active access codes',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // No Active Access
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: AppColors.warning,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        l10n.noActiveAccess,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    l10n.youDontHaveAnyActiveAccessCodes,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showErrorSnackBar(
                                        l10n.paymentScreenComingSoon,
                                      );
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: Text(l10n.getAccess),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Quick Actions
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.dashboard,
                                color: AppColors.primary,
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.quickActions,
                                style: AppTextStyles.heading3.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.quiz,
                                  label: l10n.startExam,
                                  color: AppColors.primary,
                                  onPressed: () {
                                    _showErrorSnackBar(l10n.examsComingSoon);
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.history,
                                  label: l10n.myResults,
                                  color: AppColors.success,
                                  onPressed: () {
                                    _showErrorSnackBar(l10n.resultsComingSoon);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.payment,
                                  label: l10n.getAccess,
                                  color: AppColors.warning,
                                  onPressed: () {
                                    _showErrorSnackBar(l10n.paymentComingSoon);
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.help,
                                  label: l10n.helpSupport,
                                  color: AppColors.info,
                                  onPressed: () {
                                    _showErrorSnackBar(l10n.helpComingSoon);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp),
      label: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
