import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/models/user_model.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_traffic_rules/screens/user/progress_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import '../../services/network_service.dart';

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
  final NetworkService _networkService = NetworkService();

  // Track app lifecycle to prevent unnecessary refreshes
  DateTime? _lastBackgroundTime;
  static const _minBackgroundDuration = Duration(seconds: 3);

  // Cache keys
  static const String _cacheKeyExamResults = 'cached_exam_results';
  static const String _cacheKeyExams = 'cached_exams';
  static const String _cacheKeyUserStats = 'cached_user_stats';
  static const String _cacheKeyAdminStats = 'cached_admin_stats';
  static const String _cacheKeyExamCountsByType = 'cached_exam_counts_by_type';
  static const String _cacheKeyTimestamp = 'dashboard_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(
    hours: 1,
  ); // Cache valid for 1 hour

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set initial tab based on user role
    // USER: Exams first (index 0), ADMIN: Dashboard first (index 1)
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user?.role == 'USER') {
      _currentIndex = 0; // Exams tab first for users
    } else {
      _currentIndex = 1; // Dashboard tab first for admin/manager
    }

    // Load dashboard data (will use cache if available)
    _loadDashboardData(forceRefresh: false);
    // Load courses (will use cache if available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).loadCourses(forceRefresh: false);
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
          _loadDashboardData(forceRefresh: false); // Use cache if available
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

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();

      // Try to load from cache first if offline or if cache is still valid
      if (!hasInternet || !forceRefresh) {
        final cachedDataLoaded = await _loadCachedDashboardData(user?.role);
        if (cachedDataLoaded && !forceRefresh) {
          debugPrint('📦 Using cached dashboard data');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          // If offline, use cache and return
          if (!hasInternet) {
            debugPrint('🌐 No internet - using cached data only');
            return;
          }
          // If online but cache is valid, use cache and refresh in background
          if (await _isCacheValid()) {
            debugPrint('📦 Cache is valid, refreshing in background');
            // Load fresh data in background
            _loadFreshDashboardData(user?.role);
            return;
          }
        }
      }

      // Load fresh data from API
      if (hasInternet) {
        if (user?.role == 'USER') {
          await _loadUserDashboardData();
        } else if (user?.role == 'ADMIN') {
          await _loadAdminDashboardData();
        }
      } else {
        // No internet and no cache - show error
        if (mounted) {
          setState(() {
            _error = 'No internet connection and no cached data available';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Try to load from cache on error
      final authState = ref.read(authProvider);
      final user = authState.user;
      final cachedDataLoaded = await _loadCachedDashboardData(user?.role);
      if (cachedDataLoaded) {
        debugPrint('📦 Error occurred, using cached data as fallback');
      } else if (mounted) {
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

  Future<void> _loadFreshDashboardData(String? role) async {
    try {
      if (role == 'USER') {
        await _loadUserDashboardData();
      } else if (role == 'ADMIN') {
        await _loadAdminDashboardData();
      }
    } catch (e) {
      debugPrint('Error loading fresh dashboard data: $e');
      // Silently fail - user already has cached data
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

        // Cache the data
        await _cacheDashboardData('USER');
      }
    } catch (e) {
      debugPrint('Error loading user dashboard data: $e');
      rethrow; // Re-throw to allow fallback to cache
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

      // Cache the data
      await _cacheDashboardData('ADMIN');
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
      rethrow; // Re-throw to allow fallback to cache
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

  // Cache management methods
  Future<void> _cacheDashboardData(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();

      // Cache exam results
      final examResultsJson = _examResults.map((r) => r.toJson()).toList();
      await prefs.setString(_cacheKeyExamResults, jsonEncode(examResultsJson));

      // Cache exams
      final examsJson = _exams.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKeyExams, jsonEncode(examsJson));

      // Cache exam counts by type
      final examCountsByType = <String, int>{};
      for (final exam in _exams) {
        if (exam.isActive) {
          String type = exam.examType?.toLowerCase() ?? 'english';
          if (type == 'unknown' || exam.examType == null) {
            final titleLower = exam.title.toLowerCase();
            if (titleLower.contains('kiny') ||
                titleLower.contains('kinyarwanda')) {
              type = 'kinyarwanda';
            } else if (titleLower.contains('french') ||
                titleLower.contains('français')) {
              type = 'french';
            } else {
              type = 'english';
            }
          }
          examCountsByType[type] = (examCountsByType[type] ?? 0) + 1;
        }
      }
      await prefs.setString(
        _cacheKeyExamCountsByType,
        jsonEncode(examCountsByType),
      );

      // Cache stats based on role
      if (role == 'USER') {
        await prefs.setString(
          _cacheKeyUserStats,
          jsonEncode({
            'totalExamsTaken': _totalExamsTaken,
            'averageScore': _averageScore,
            'studyStreak': _studyStreak,
            'achievements': _achievements,
          }),
        );
      } else if (role == 'ADMIN') {
        await prefs.setString(
          _cacheKeyAdminStats,
          jsonEncode({
            'totalUsers': _totalUsers,
            'totalExams': _totalExams,
            'totalExamResults': _totalExamResults,
            'averageScore': _averageScore,
          }),
        );
      }

      // Cache timestamp
      await prefs.setString(_cacheKeyTimestamp, timestamp);

      debugPrint('💾 Cached dashboard data at $timestamp');
    } catch (e) {
      debugPrint('Error caching dashboard data: $e');
    }
  }

  Future<bool> _loadCachedDashboardData(String? role) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      final examResultsJson = prefs.getString(_cacheKeyExamResults);
      final examsJson = prefs.getString(_cacheKeyExams);

      if (examResultsJson == null || examsJson == null) {
        debugPrint('📦 No cached dashboard data found');
        return false;
      }

      // Load exam results
      final examResultsList = jsonDecode(examResultsJson) as List;
      _examResults = examResultsList
          .map((json) => ExamResultData.fromJson(json as Map<String, dynamic>))
          .toList();

      // Load exams
      final examsList = jsonDecode(examsJson) as List;
      _exams = examsList
          .map((json) => Exam.fromJson(json as Map<String, dynamic>))
          .toList();

      // Load exam counts by type from cache
      final examCountsJson = prefs.getString(_cacheKeyExamCountsByType);
      if (examCountsJson != null) {
        try {
          final examCounts = jsonDecode(examCountsJson) as Map<String, dynamic>;
          // Store exam counts for use in _buildExamsByType
          // This will be used to show counts even when offline
        } catch (e) {
          // Ignore parse errors
        }
      }

      // Load stats based on role
      if (role == 'USER') {
        final statsJson = prefs.getString(_cacheKeyUserStats);
        if (statsJson != null) {
          final stats = jsonDecode(statsJson) as Map<String, dynamic>;
          _totalExamsTaken = stats['totalExamsTaken'] as int? ?? 0;
          _averageScore = (stats['averageScore'] as num?)?.toDouble() ?? 0.0;
          _studyStreak = stats['studyStreak'] as int? ?? 0;
          _achievements = stats['achievements'] as int? ?? 0;
        } else {
          _calculateUserStats();
        }
      } else if (role == 'ADMIN') {
        final statsJson = prefs.getString(_cacheKeyAdminStats);
        if (statsJson != null) {
          final stats = jsonDecode(statsJson) as Map<String, dynamic>;
          _totalUsers = stats['totalUsers'] as int? ?? 0;
          _totalExams = stats['totalExams'] as int? ?? 0;
          _totalExamResults = stats['totalExamResults'] as int? ?? 0;
          _averageScore = (stats['averageScore'] as num?)?.toDouble() ?? 0.0;
        } else {
          _calculateAdminStats();
        }
      } else {
        // Calculate stats if role is unknown
        if (role == 'USER') {
          _calculateUserStats();
        } else {
          _calculateAdminStats();
        }
      }

      if (mounted) {
        setState(() {});
      }

      debugPrint('📦 Loaded cached dashboard data');
      return true;
    } catch (e) {
      debugPrint('Error loading cached dashboard data: $e');
      return false;
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheKeyTimestamp);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final age = now.difference(timestamp);

      return age < _cacheValidityDuration;
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
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
          _buildExamsTab(), // Index 0: Exams (first tab)
          _buildDashboardTab(), // Index 1: Dashboard (second tab)
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
          if (index == 0) {
            // Exams is now index 0
            _clearShownNotifications();
          }

          // Reload data when switching to dashboard or exams tab
          if (index == 0 || index == 1) {
            // Exams (0) or Dashboard (1)
            // Small delay to ensure state is updated
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && _currentIndex == index) {
                _loadDashboardData(
                  forceRefresh: false,
                ); // Use cache if available
              }
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            label: user?.role == 'ADMIN' ? 'Manage Exams' : 'Exams',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Show exit confirmation dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.exit_to_app,
                    color: AppColors.warning,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  const Text('Exit App?'),
                ],
              ),
              content: const Text(
                'Are you sure you want to exit the app?',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );

          if (shouldExit == true && mounted) {
            // Exit the app
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadDashboardData(forceRefresh: true),
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
          onRefresh: () => _loadDashboardData(forceRefresh: true),
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
              onPressed: () => _loadDashboardData(forceRefresh: true),
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
            isAdmin
                ? 'Admin Dashboard'
                : 'Welcome back ${user?.fullName ?? 'User'}!',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.white,
              fontSize: 18.sp,
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
                  _currentIndex = 0; // Switch to exams tab (now first tab)
                });
              } else if (accessPeriod?.hasAccess == true &&
                  (accessPeriod?.remainingDays ?? 0) > 0) {
                setState(() {
                  _currentIndex = 0; // Switch to exams tab (now first tab)
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
                    _currentIndex = 0; // Switch to exams tab (now first tab)
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

    // If no exams loaded, try to load cached exam counts
    if (examsByType.isEmpty) {
      return FutureBuilder<Map<String, int>?>(
        future: _loadCachedExamCounts(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final cachedCounts = snapshot.data!;
            // Create exam type cards from cached counts
            final orderedTypes = ['kinyarwanda', 'english', 'french'];
            final availableTypes = orderedTypes
                .where((type) => cachedCounts.containsKey(type))
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
                    Icon(
                      Icons.quiz_outlined,
                      size: 48.sp,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No exams available',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.grey600,
                      ),
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
                    final count = cachedCounts[type] ?? 0;
                    return _buildExamTypeCard(type, [], cachedCount: count);
                  },
                ),
              ],
            );
          }

          // No cached data either
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
                Icon(
                  Icons.quiz_outlined,
                  size: 48.sp,
                  color: AppColors.grey400,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No exams available',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      );
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
            final exams = examsByType[type] ?? [];
            return FutureBuilder<Map<String, int>?>(
              future: _loadCachedExamCounts(),
              builder: (context, snapshot) {
                final cachedCount = snapshot.data?[type];
                return _buildExamTypeCard(
                  type,
                  exams,
                  cachedCount: cachedCount,
                );
              },
            );
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
        else if (courseState.error != null && courseState.courses.isEmpty)
          // Only show error if we have no cached courses
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

  Future<Map<String, int>?> _loadCachedExamCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final examCountsJson = prefs.getString(_cacheKeyExamCountsByType);
      if (examCountsJson == null) return null;

      final examCounts = jsonDecode(examCountsJson) as Map<String, dynamic>;
      return examCounts.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return null;
    }
  }

  Widget _buildExamTypeCard(
    String examType,
    List<Exam> exams, {
    int? cachedCount,
  }) {
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
                      '${cachedCount ?? exams.length} ${(cachedCount ?? exams.length) == 1 ? 'Exam' : 'Exams'}',
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
              'Share App',
              'Share this app with friends and family',
              Icons.share,
              () {
                _shareApp();
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
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error, size: 24.sp),
                        SizedBox(width: 8.w),
                        const Text('Logout'),
                      ],
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: AppTextStyles.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && mounted) {
                  // Perform logout
                  await ref.read(authProvider.notifier).logout();

                  // Navigate to login screen explicitly
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false, // Remove all previous routes
                    );
                  }
                }
              },
              backgroundColor: AppColors.error,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      const playStoreLink =
          'https://play.google.com/store/apps/details?id=com.trafficrules.master';
      final shareText =
          '''
🚗 Rwanda Traffic Rule 🇷🇼 - Master Your Driving Test!

Download the best app to prepare for your provisional driving license exam.

📱 App: $appName
📦 Version: $version ($buildNumber)

✨ Features:
• Interactive practice tests
• Comprehensive study materials
• Road signs and traffic rules
• Progress tracking
• Available in English, Kinyarwanda, and French

📥 Download now:
$playStoreLink

Start your journey to becoming a safe driver!
#TrafficRules #DrivingTest #LearnToDrive
''';
      await Share.share(
        shareText,
        subject: 'Rwanda Traffic Rule 🇷🇼 - Driving Test Preparation App',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share app: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
