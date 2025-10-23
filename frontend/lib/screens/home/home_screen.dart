import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/models/user_model.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_traffic_rules/screens/user/progress_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../services/exam_service.dart';
import '../../services/user_management_service.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import '../admin/exam_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/access_code_management_screen.dart';
import '../user/available_exams_screen.dart';
import '../../services/notification_polling_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Dashboard data
  List<ExamResultData> _examResults = [];
  List<Exam> _exams = [];
  bool _isLoading = true;
  String _error = '';

  // User stats
  int _totalExamsTaken = 0;
  double _averageScore = 0.0;
  int _studyStreak = 0;
  int _achievements = 0;

  // Admin stats
  int _totalUsers = 0;
  int _totalExams = 0;
  int _totalExamResults = 0;

  final ExamService _examService = ExamService();
  final UserManagementService _userManagementService = UserManagementService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _clearShownNotifications() {
    // Clear shown notifications when user opens exams
    NotificationPollingService().clearShownNotifications();
    debugPrint('🧹 Cleared shown notifications - user opened exams');
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user?.role == 'USER') {
        await _loadUserDashboardData();
      } else if (user?.role == 'ADMIN') {
        await _loadAdminDashboardData();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDashboardData() async {
    try {
      // Load user's exam results
      _examResults = await _examService.getUserExamResults();
      _calculateUserStats();
    } catch (e) {
      debugPrint('Error loading user dashboard data: $e');
    }
  }

  Future<void> _loadAdminDashboardData() async {
    try {
      // Load all exam results for admin stats
      _examResults = await _examService.getUserExamResults();

      // Load exams data
      _exams = await _examService.getAvailableExams();

      // Load user statistics to get total users
      try {
        final userStats = await _userManagementService.getUserStatistics();
        _totalUsers = userStats.data.users.total;
      } catch (e) {
        debugPrint('Error loading user statistics: $e');
        // Fallback to calculating from exam results
        final uniqueUsers = _examResults.map((r) => r.userId).toSet();
        _totalUsers = uniqueUsers.length;
      }

      _calculateAdminStats();
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
    }
  }

  void _calculateUserStats() {
    if (_examResults.isEmpty) return;

    // Get unique exams (most recent attempt for each exam)
    final uniqueResults = <String, ExamResultData>{};
    for (final result in _examResults) {
      if (!uniqueResults.containsKey(result.examId) ||
          result.submittedAt.isAfter(
            uniqueResults[result.examId]!.submittedAt,
          )) {
        uniqueResults[result.examId] = result;
      }
    }

    _totalExamsTaken = uniqueResults.length;

    if (uniqueResults.isNotEmpty) {
      _averageScore =
          uniqueResults.values.map((r) => r.score).reduce((a, b) => a + b) /
          uniqueResults.length;
    }

    // Calculate study streak (consecutive days with exam attempts)
    _studyStreak = _calculateStudyStreak();

    // Calculate achievements based on performance
    _achievements = _calculateAchievements(uniqueResults.values.toList());
  }

  void _calculateAdminStats() {
    _totalExams = _exams.length;
    _totalExamResults = _examResults.length;

    // _totalUsers is already set from getUserStatistics() in _loadAdminDashboardData()
    // Only calculate from exam results if getUserStatistics() failed
    if (_totalUsers == 0) {
      final uniqueUsers = _examResults.map((r) => r.userId).toSet();
      _totalUsers = uniqueUsers.length;
    }
  }

  int _calculateStudyStreak() {
    if (_examResults.isEmpty) return 0;

    // Sort results by date (most recent first)
    final sortedResults = List<ExamResultData>.from(_examResults)
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    int streak = 0;
    DateTime? lastExamDate;

    for (final result in sortedResults) {
      final examDate = DateTime(
        result.submittedAt.year,
        result.submittedAt.month,
        result.submittedAt.day,
      );

      if (lastExamDate == null) {
        streak = 1;
        lastExamDate = examDate;
      } else {
        final daysDifference = lastExamDate.difference(examDate).inDays;
        if (daysDifference == 1) {
          streak++;
          lastExamDate = examDate;
        } else if (daysDifference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  int _calculateAchievements(List<ExamResultData> results) {
    int achievements = 0;

    // Achievement 1: First exam taken
    if (results.isNotEmpty) achievements++;

    // Achievement 2: First exam passed
    if (results.any((r) => r.passed)) achievements++;

    // Achievement 3: Perfect score (100%)
    if (results.any((r) => r.score == 100)) achievements++;

    // Achievement 4: 5 exams completed
    if (results.length >= 5) achievements++;

    // Achievement 5: 10 exams completed
    if (results.length >= 10) achievements++;

    // Achievement 6: Average score above 80%
    if (results.isNotEmpty) {
      final avgScore =
          results.map((r) => r.score).reduce((a, b) => a + b) / results.length;
      if (avgScore >= 80) achievements++;
    }

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildExamsTab(),
          _buildProgressTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Clear shown notifications when user opens exams tab
          if (index == 1) {
            _clearShownNotifications();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            label: user?.role == 'ADMIN' ? 'Manage Exams' : 'Exams',
          ),
          BottomNavigationBarItem(
            icon: user?.role == 'USER'
                ? const Icon(Icons.analytics)
                : const Icon(Icons.group),
            label: user?.role == 'USER' ? 'Progress' : 'Manage Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.grey50, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Card
                      _buildWelcomeCard(user),
                      SizedBox(height: 24.h),

                      // Admin Quick ActionsR
                      if (user?.role == 'ADMIN') ...[
                        _buildAdminSection(),
                        SizedBox(height: 24.h),
                      ],

                      // Quick Stats
                      _buildQuickStats(user),
                      SizedBox(height: 24.h),

                      // Recent Activity
                      _buildRecentActivity(user),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Dashboard',
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 8.h),
            Text(
              _error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Retry',
              onPressed: _loadDashboardData,
              backgroundColor: AppColors.primary,
              width: 120.w,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentInstructions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentInstructionsScreen(),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    final isAdmin = user?.role == 'ADMIN';
    final authState = ref.watch(authProvider);
    final accessPeriod = authState.accessPeriod;

    // Debug logging
    debugPrint('🔍 DEBUG - User role: ${user?.role}');
    debugPrint('🔍 DEBUG - Is admin: $isAdmin');
    debugPrint('🔍 DEBUG - Access period: $accessPeriod');
    debugPrint('🔍 DEBUG - Has access: ${accessPeriod?.hasAccess}');
    debugPrint('🔍 DEBUG - Remaining days: ${accessPeriod?.remainingDays}');

    // Force logout and re-login for testing
    if (accessPeriod == null && user?.role == 'USER') {
      debugPrint('🔍 DEBUG - Access period is null, forcing re-login...');
      // This will trigger a re-login which should load the access period
    }

    // Debug: Check what's stored in SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugStoredData();
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Admin Dashboard' : 'Welcome back!',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.white,
              fontSize: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isAdmin
                ? 'Manage your traffic rules learning platform'
                : 'Ready to master traffic rules?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),

          // Access Period Information for regular users
          if (!isAdmin) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color:
                          accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0
                          ? Icons.access_time
                          : accessPeriod?.hasAccess == true &&
                                (accessPeriod?.remainingDays ?? 0) == 0
                          ? Icons.schedule
                          : Icons.lock,
                      color: AppColors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accessPeriod?.hasAccess == true &&
                                  (accessPeriod?.remainingDays ?? 0) > 0
                              ? 'Access Active - ${accessPeriod?.remainingDays} days left'
                              : accessPeriod?.hasAccess == true &&
                                    (accessPeriod?.remainingDays ?? 0) == 0
                              ? 'Access Expired'
                              : 'No Access Code',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        if (accessPeriod?.hasAccess == true &&
                            (accessPeriod?.remainingDays ?? 0) > 0) ...[
                          SizedBox(height: 2.h),
                          Text(
                            'Payment Tier: ${accessPeriod?.paymentTier ?? 'None'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),
          CustomButton(
            text: isAdmin
                ? 'Manage Platform'
                : (accessPeriod?.hasAccess == true &&
                      (accessPeriod?.remainingDays ?? 0) > 0)
                ? 'Start Learning'
                : 'Get Access Code',
            onPressed: () {
              if (isAdmin) {
                setState(() {
                  _currentIndex = 1; // Switch to exams tab
                });
              } else if (accessPeriod?.hasAccess == true &&
                  (accessPeriod?.remainingDays ?? 0) > 0) {
                setState(() {
                  _currentIndex = 1; // Switch to exams tab
                });
              } else {
                // Show access code instructions
                //_showContactSupportDialog();
                _showPaymentInstructions();
              }
            },
            backgroundColor: AppColors.white,
            textColor: AppColors.primary,
            width: 150.w,
          ),
        ],
      ),
    );
  }

  Future<void> _debugStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessPeriodJson = prefs.getString('access_period');

      if (accessPeriodJson != null) {
        debugPrint('   Access period JSON: $accessPeriodJson');
        try {
          final accessPeriodData = json.decode(accessPeriodJson);
          debugPrint('   Parsed access period: $accessPeriodData');
        } catch (e) {
          debugPrint('   Error parsing access period: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ DEBUG STORED DATA ERROR: $e');
    }
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Actions',
          style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
        ),
        SizedBox(height: 16.h),

        Row(
          children: [
            Expanded(
              child: _buildAdminActionCard(
                'Manage Users',
                'View, search, and manage all users',
                Icons.people,
                AppColors.primary,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildAdminActionCard(
                'Manage Exams',
                'Create, edit, and manage exams',
                Icons.quiz,
                AppColors.success,
                () {
                  setState(() {
                    _currentIndex = 1; // Switch to exams tab
                  });
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: _buildAdminActionCard(
                'Access Codes',
                'Manage access codes and payments',
                Icons.vpn_key,
                AppColors.warning,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccessCodeManagementScreen(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(), // Empty space for alignment
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(User? user) {
    final isAdmin = user?.role == 'ADMIN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
        ),
        SizedBox(height: 16.h),

        if (isAdmin) ...[
          // Admin stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '$_totalUsers',
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Total Exams',
                  '$_totalExams',
                  Icons.quiz,
                  AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Attempts',
                  '$_totalExamResults',
                  Icons.analytics,
                  AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Avg Score',
                  '${_averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ] else ...[
          // User stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Exams Taken',
                  '$_totalExamsTaken',
                  Icons.quiz,
                  AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Average Score',
                  '${_averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Study Streak',
                  '$_studyStreak days',
                  Icons.local_fire_department,
                  AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Achievements',
                  '$_achievements',
                  Icons.emoji_events,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecentActivity(User? user) {
    final isAdmin = user?.role == 'ADMIN';
    final recentResults = _examResults.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAdmin ? 'Recent Activity' : 'Recent Activity',
          style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
        ),
        SizedBox(height: 16.h),

        if (recentResults.isEmpty)
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
                Icon(Icons.history, size: 48.sp, color: AppColors.grey400),
                SizedBox(height: 16.h),
                Text(
                  'No recent activity',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isAdmin
                      ? 'No exam attempts recorded yet'
                      : 'Start taking exams to see your progress here',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
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
              children: recentResults.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: result.passed
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: result.passed
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.passed ? Icons.check_circle : Icons.cancel,
                        color: result.passed ? Colors.green : Colors.red,
                        size: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.exam?.title ?? 'Exam ${index + 1}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Score: ${result.score}% • ${_formatTimeAgo(result.submittedAt)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 18.sp,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            Icon(icon, size: 24.sp, color: color),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.sp,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'ADMIN';

    if (isAdmin) {
      return const ExamManagementScreen();
    }

    return const AvailableExamsScreen();
  }

  Widget _buildProgressTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isUser = user?.role == 'USER';

    if (isUser) {
      return const ProgressScreen();
    }
    return const UserManagementScreen();
  }

  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Card
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
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    user?.fullName ?? 'User',
                    style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user?.phoneNumber ?? 'No phone number',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      user?.role ?? 'USER',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Settings Options
            _buildSettingsOption(
              'View Profile',
              'View and manage your profile information',
              Icons.person_outline,
              () {
                Navigator.pushNamed(context, '/view-profile');
              },
            ),

            _buildSettingsOption(
              'Notifications',
              'Manage your notification preferences',
              Icons.notifications,
              () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),

            _buildSettingsOption(
              'Study Reminders',
              'Set up study reminders',
              Icons.schedule,
              () {
                Navigator.pushNamed(context, '/study-reminders');
              },
            ),

            _buildSettingsOption(
              'About App',
              'Learn more about this application',
              Icons.info_outline,
              () {
                Navigator.pushNamed(context, '/about-app');
              },
            ),

            _buildSettingsOption(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip_outlined,
              () {
                Navigator.pushNamed(context, '/privacy-policy');
              },
            ),

            _buildSettingsOption(
              'Terms & Conditions',
              'Read our terms and conditions',
              Icons.description_outlined,
              () {
                Navigator.pushNamed(context, '/terms-conditions');
              },
            ),

            _buildSettingsOption(
              'Help & Support',
              'Get help and contact support',
              Icons.help,
              () {
                Navigator.pushNamed(context, '/help-support');
              },
            ),

            _buildSettingsOption(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              () {
                Navigator.pushNamed(context, '/delete-account');
              },
              isDestructive: true,
            ),

            SizedBox(height: 24.h),

            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              backgroundColor: AppColors.error,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.grey800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.8)
                : AppColors.grey600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: AppColors.grey400,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tileColor: AppColors.white,
      ),
    );
  }
}
