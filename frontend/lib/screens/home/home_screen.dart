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
import '../../providers/exam_provider.dart';
import '../../widgets/custom_button.dart';
import '../../services/exam_service.dart';
import '../../services/user_management_service.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import '../../models/course_model.dart';
import '../admin/exam_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/access_code_management_screen.dart';
import '../admin/course_management_screen.dart';
import '../user/available_exams_screen.dart';
import '../user/course_list_screen.dart';
import '../user/course_detail_screen.dart';
import '../../services/notification_polling_service.dart';
import '../../providers/course_provider.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
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

  // Track app lifecycle to prevent unnecessary refreshes
  DateTime? _lastBackgroundTime;
  static const _minBackgroundDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
    // Load courses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).loadCourses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only reload if app was in background for a meaningful duration
    // This prevents refresh when taking screenshots (which briefly triggers inactive/resumed)
    // Screenshots trigger: inactive -> resumed (very quickly, < 1 second)
    // Real background: paused -> resumed (usually > 3 seconds)
    if (state == AppLifecycleState.paused) {
      // Only track paused state, not inactive (screenshots trigger inactive)
      _lastBackgroundTime = DateTime.now();
      debugPrint('🔄 App paused, tracking background time');
    } else if (state == AppLifecycleState.resumed) {
      // Only reload if app was paused (in background) for at least 3 seconds
      // Ignore inactive->resumed transitions (screenshots)
      if (_lastBackgroundTime != null) {
        final backgroundDuration = DateTime.now().difference(
          _lastBackgroundTime!,
        );
        if (backgroundDuration >= _minBackgroundDuration) {
          debugPrint(
            '🔄 App resumed after ${backgroundDuration.inSeconds}s, reloading data',
          );
          _loadDashboardData();
        } else {
          debugPrint(
            '🔄 App resumed quickly (${backgroundDuration.inSeconds}s), skipping reload (likely screenshot)',
          );
        }
        _lastBackgroundTime = null;
      }
    } else if (state == AppLifecycleState.inactive) {
      // Screenshots trigger inactive state - don't track this
      // Only track if we were already paused
      if (_lastBackgroundTime == null) {
        debugPrint('🔄 App inactive (likely screenshot), ignoring');
      }
    }
  }

  void _clearShownNotifications() {
    // Clear shown notifications when user opens exams
    NotificationPollingService().clearShownNotifications();
    debugPrint('🧹 Cleared shown notifications - user opened exams');
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user?.role == 'USER') {
        await _loadUserDashboardData();
      } else if (user?.role == 'ADMIN') {
        await _loadAdminDashboardData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserDashboardData() async {
    try {
      // Load user's exam results
      _examResults = await _examService.getUserExamResults();
      // Load available exams to display grouped by type
      // Force reload from API to get latest exams
      final freshExams = await _examService.getAvailableExams();
      if (mounted) {
        setState(() {
          _exams = freshExams;
        });
        _calculateUserStats();
        debugPrint('✅ Loaded ${freshExams.length} exams for user dashboard');
      }
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

    // Watch exam provider to reload when exams change (for admin)
    // This ensures exam cards update when new exams are created
    final examState = ref.watch(examProvider);

    // Track previous exam count to detect changes
    final previousExamCount = _exams.length;

    // Reload exams when exam provider state changes (for admin creating/updating exams)
    // For admin: examProvider is populated when they access exam management screen
    // For users: examProvider might be empty, so we rely on tab switching and pull-to-refresh
    if (user?.role == 'ADMIN' && examState.exams.isNotEmpty) {
      // Use a post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only reload if exams count changed or if we don't have exams loaded
        if (previousExamCount != examState.exams.length || _exams.isEmpty) {
          debugPrint(
            '🔄 Exam provider changed (${previousExamCount} -> ${examState.exams.length}), reloading dashboard data',
          );
          _loadDashboardData();
        }
      });
    }

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

          // Reload data when switching to dashboard or exams tab
          if (index == 0 || index == 1) {
            // Small delay to ensure state is updated
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && _currentIndex == index) {
                _loadDashboardData();
              }
            });
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
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: Container(
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
                    physics: const AlwaysScrollableScrollPhysics(),
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

                        // Quick Stats (for admin only)
                        if (user?.role == 'ADMIN') ...[
                          _buildQuickStats(user),
                          SizedBox(height: 24.h),
                        ],

                        // Exams grouped by type (for users)
                        if (user?.role == 'USER') ...[
                          _buildExamsByType(),
                          SizedBox(height: 24.h),
                          _buildCoursesSection(),
                          SizedBox(height: 24.h),
                          // Quick Stats for users
                          _buildQuickStats(user),
                          SizedBox(height: 24.h),
                        ],

                        // Recent Activity
                        _buildRecentActivity(user),
                      ],
                    ),
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
              child: _buildAdminActionCard(
                'Manage Courses',
                'Create, edit, and manage courses',
                Icons.school,
                AppColors.secondary,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseManagementScreen(),
                  ),
                ),
              ),
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

  Widget _buildExamsByType() {
    // Group exams by type
    final Map<String, List<Exam>> examsByType = {};

    // Get unique exam types from database
    final activeExams = _exams.where((exam) => exam.isActive).toList();

    for (final exam in activeExams) {
      // Handle null examType: default to 'english' if null
      // Also try to infer from title if it contains language keywords
      String type = exam.examType?.toLowerCase() ?? 'english';

      // If examType is null or 'unknown', try to infer from title
      if (type == 'unknown' || exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        } else {
          type = 'english'; // Default to english
        }
      }

      examsByType.putIfAbsent(type, () => []).add(exam);
    }

    // Order: kinyarwanda, english, french
    final orderedTypes = ['kinyarwanda', 'english', 'french'];
    final availableTypes = orderedTypes
        .where((type) => examsByType.containsKey(type))
        .toList();

    if (availableTypes.isEmpty) {
      return Container(
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
            Icon(Icons.quiz_outlined, size: 48.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              'No exams available',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Exams',
          style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
        ),
        SizedBox(height: 16.h),
        // Show exam type cards in a grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: availableTypes.length,
          itemBuilder: (context, index) {
            final type = availableTypes[index];
            final exams = examsByType[type]!;
            return _buildExamTypeCard(type, exams);
          },
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    final courseState = ref.watch(courseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Courses',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseListScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'View All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),
        if (courseState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (courseState.error != null)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              'Error loading courses: ${courseState.error}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          )
        else if (courseState.courses.isEmpty)
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48.sp,
                  color: AppColors.grey400,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No courses available',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courseState.courses.take(5).length,
              itemBuilder: (context, index) {
                final course = courseState.courses[index];
                return Container(
                  width: 200.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: _buildCourseCard(course),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey200, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Course Image or Placeholder
            Container(
              height: 100.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                color: AppColors.grey100,
              ),
              child:
                  course.courseImageUrl != null &&
                      course.courseImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      child: Image.network(
                        course.courseImageUrl!.startsWith('http')
                            ? course.courseImageUrl!
                            : '${AppConstants.baseUrlImage}${course.courseImageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.grey100,
                            child: Center(
                              child: Icon(
                                Icons.school_outlined,
                                size: 32.sp,
                                color: AppColors.grey400,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.school_outlined,
                        size: 32.sp,
                        color: AppColors.grey400,
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: course.isFree
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          course.courseType.displayName,
                          style: AppTextStyles.caption.copyWith(
                            color: course.isFree
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                      Text(
                        '${course.contentCount ?? 0} lessons',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamTypeCard(String examType, List<Exam> exams) {
    // Get display name and icon for each exam type
    String displayName;
    IconData icon;
    Color cardColor;

    switch (examType.toLowerCase()) {
      case 'english':
        displayName = 'English';
        icon = Icons.language;
        cardColor = AppColors.primary;
        break;
      case 'kinyarwanda':
        displayName = 'Kinyarwanda';
        icon = Icons.translate;
        cardColor = AppColors.secondary;
        break;
      case 'french':
        displayName = 'French';
        icon = Icons.public;
        cardColor = Colors.blue;
        break;
      default:
        displayName = examType[0].toUpperCase() + examType.substring(1);
        icon = Icons.quiz;
        cardColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to available exams screen filtered by this exam type
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AvailableExamsScreen(initialExamType: examType),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(icon, size: 20.sp, color: cardColor),
                    ),
                    // SizedBox(height: 4.h),
                    Text(
                      displayName,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.grey800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${exams.length} ${exams.length == 1 ? 'Exam' : 'Exams'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
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

    //disble back button when user are on dashboard screen
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
