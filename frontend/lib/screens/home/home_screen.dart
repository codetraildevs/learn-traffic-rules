import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/models/user_model.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart'
    as payment_screen;
import 'package:learn_traffic_rules/screens/user/pdf_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_traffic_rules/screens/user/progress_screen.dart'
    as progress_screen;
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/custom_button.dart';
import '../../services/exam_service.dart';
import '../../services/user_management_service.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import '../admin/exam_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/access_code_management_screen.dart';
import '../admin/course_management_screen.dart';
import '../user/available_exams_screen.dart' as exams_screen;
import '../user/course_list_screen.dart' as courses_list_screen;
import '../../services/notification_polling_service.dart';
import '../../providers/course_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/network_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/image_cache_service.dart';
import '../user/open_gazette.dart';

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

    // OPTIMIZATION: Load from cache FIRST for instant display
    // Then fetch from API in background
    _loadDashboardData(forceRefresh: false);

    // Load courses and pre-cache images in background (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).loadCourses(forceRefresh: false);
      _precacheServiceImages(); // Non-blocking
    });
  }

  void _precacheServiceImages() {
    // Pre-cache all images used in service cards
    final imageUrls = [
      '${AppConstants.imageBaseUrl}ishuri_online.png',
      '${AppConstants.imageBaseUrl}ishuri_online.png',
      '${AppConstants.imageBaseUrl}official_roads_signs.png',
      '${AppConstants.imageBaseUrl}official_gazette.png',
    ];

    for (final imageUrl in imageUrls) {
      ImageCacheService.instance.cacheImage(imageUrl);
    }
    debugPrint('✅ Pre-cached ${imageUrls.length} service card images');
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
          // Refresh access period when app comes to foreground
          final authNotifier = ref.read(authProvider.notifier);
          authNotifier.refreshAccessPeriod();
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
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      // OPTIMIZATION: Load from cache FIRST for instant display
      final cachedDataLoaded = await _loadCachedDashboardData(user?.role);

      if (cachedDataLoaded && !forceRefresh) {
        // Show cached data immediately
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = '';
          });
        }
      } else {
        // No cache or force refresh - show loading
        if (mounted) {
          setState(() {
            _isLoading = true;
            _error = '';
          });
        }
      }

      // Check internet connection in parallel
      final hasInternetFuture = _networkService.hasInternetConnection();

      // If we have cached data, show it and fetch fresh data in background
      if (cachedDataLoaded && !forceRefresh) {
        final hasInternet = await hasInternetFuture;

        if (hasInternet) {
          // Fetch fresh data in background (non-blocking)
          _loadFreshDashboardData(user?.role).catchError((e) {
            debugPrint('⚠️ Background refresh failed: $e');
          });
        }
        return; // Exit early - UI already shown with cache
      }

      // No cache or force refresh - must wait for API
      final hasInternet = await hasInternetFuture;

      if (hasInternet) {
        // Load fresh data from API
        if (user?.role == 'USER') {
          await _loadUserDashboardData();
        } else if (user?.role == 'ADMIN') {
          await _loadAdminDashboardData();
        }
      } else {
        // No internet and no cache - show error
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _error = l10n.noInternetConnectionAndNoCachedDataAvailable;
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = '';
          });
        }
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = '${l10n.failedToLoadDashboardData}: $e';
          _isLoading = false;
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

      // Update UI with fresh data
      if (mounted) {
        setState(() {
          // Data already updated in _loadUserDashboardData or _loadAdminDashboardData
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading fresh dashboard data: $e');
      // Silently fail - user already has cached data displayed
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

        // Clear image caches to ensure fresh images from backend are loaded
        ImageCacheService.instance.clearAllCaches();

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

      // Clear image caches to ensure fresh images from backend are loaded
      ImageCacheService.instance.clearAllCaches();

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
          // Exam counts are cached for use in _buildAvailableServicesCard
          // This will be used to show counts even when offline
          jsonDecode(examCountsJson) as Map<String, dynamic>;
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
            '🔄 Exam provider changed ($previousExamCount -> ${examState.exams.length}), reloading dashboard data',
          );
          _loadDashboardData();
        }
      });
    }

    final l10n = AppLocalizations.of(context);
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
                if (index == 0) {
                  // Exams tab - refresh access period and reload exams
                  final authNotifier = ref.read(authProvider.notifier);
                  authNotifier.refreshAccessPeriod();
                }
                _loadDashboardData(
                  forceRefresh: false,
                ); // Use cache if available
              }
            });
          }
          // Progress tab (2) refresh is handled by ProgressScreen via
          // isVisible in didUpdateWidget when tab becomes visible
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            label: user?.role == 'ADMIN' ? l10n.manageExamsLabel : l10n.exams,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: user?.role == 'USER'
                ? const Icon(Icons.analytics)
                : const Icon(Icons.group),
            label: user?.role == 'USER' ? l10n.progress : l10n.manageUsers,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.profile,
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
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      color: AppColors.warning,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(l10n.exitApp),
                  ],
                ),
                content: Text(
                  l10n.areYouSureYouWantToExitApp,
                  style: AppTextStyles.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(l10n.exit),
                  ),
                ],
              );
            },
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
          title: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(l10n.dashboard);
            },
          ),
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
                          SizedBox(height: 12.h),

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

                          // Available Services (for users)
                          if (user?.role == 'USER') ...[
                            _buildAvailableServicesCard(),
                            SizedBox(height: 12.h),
                            // Quick Stats for users
                            // _buildQuickStats(user),
                            //SizedBox(height: 24.h),
                          ],
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Column(
                  children: [
                    Text(
                      l10n.errorLoadingDashboard,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.error,
                      ),
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
                      text: l10n.retry,
                      onPressed: () => _loadDashboardData(forceRefresh: true),
                      backgroundColor: AppColors.primary,
                      width: 120.w,
                    ),
                  ],
                );
              },
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
        builder: (context) => const payment_screen.PaymentInstructionsScreen(),
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

    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Welcome Text
              Text(
                isAdmin
                    ? l10n.adminDashboard
                    : l10n.welcomeBack(user?.fullName ?? 'User'),
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.grey800,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              Text(
                isAdmin
                    ? l10n.manageYourTrafficRulesLearningPlatform
                    : l10n.readyToMasterTrafficRules,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                  fontSize: 12.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Access Period Information for regular users
              if (!isAdmin) ...[
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0
                          ? Icons.access_time
                          : accessPeriod?.hasAccess == true &&
                                (accessPeriod?.remainingDays ?? 0) == 0
                          ? Icons.schedule
                          : Icons.lock,
                      size: 16.sp,
                      color:
                          accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accessPeriod?.hasAccess == true &&
                                    (accessPeriod?.remainingDays ?? 0) > 0
                                ? l10n.accessActiveDaysLeft(
                                    accessPeriod!.remainingDays,
                                  )
                                : accessPeriod?.hasAccess == true &&
                                      (accessPeriod?.remainingDays ?? 0) == 0
                                ? l10n.accessExpired
                                : l10n.noAccessCode,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey800,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0) ...[
                            SizedBox(height: 2.h),
                            Text(
                              '${l10n.paymentTier} ${accessPeriod?.paymentTier ?? l10n.none}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey600,
                                fontSize: 10.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Action Button
              if (!isAdmin) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (accessPeriod?.hasAccess == true &&
                          (accessPeriod?.remainingDays ?? 0) > 0) {
                        setState(() {
                          _currentIndex = 0; // Switch to exams tab
                        });
                      } else {
                        _showPaymentInstructions();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      (accessPeriod?.hasAccess == true &&
                              (accessPeriod?.remainingDays ?? 0) > 0)
                          ? l10n.startLearning
                          : l10n.getAccessCode,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0; // Switch to exams tab
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.managePlatform,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n.adminActions,
              style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
            );
          },
        ),
        SizedBox(height: 16.h),

        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildAdminActionCard(
                    l10n.manageUsers,
                    l10n.viewSearchAndManageAllUsers,
                    Icons.people,
                    AppColors.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildAdminActionCard(
                    l10n.manageExams,
                    l10n.createEditAndManageExams,
                    Icons.quiz,
                    AppColors.success,
                    () {
                      setState(() {
                        _currentIndex =
                            0; // Switch to exams tab (now first tab)
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildAdminActionCard(
                    l10n.accessCodes,
                    l10n.manageAccessCodesAndPayments,
                    Icons.vpn_key,
                    AppColors.warning,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AccessCodeManagementScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildAdminActionCard(
                    l10n.manageCourses,
                    l10n.createEditAndManageCourses,
                    Icons.school,
                    AppColors.secondary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CourseManagementScreen(),
                      ),
                    ),
                  );
                },
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
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n.quickStats,
              style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
            );
          },
        ),
        SizedBox(height: 16.h),

        if (isAdmin) ...[
          // Admin stats
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.totalUsersLabel,
                      '$_totalUsers',
                      Icons.people,
                      AppColors.primary,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.totalExams,
                      '$_totalExams',
                      Icons.quiz,
                      AppColors.success,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.totalAttempts,
                      '$_totalExamResults',
                      Icons.analytics,
                      AppColors.warning,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.avgScore,
                      '${_averageScore.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      AppColors.secondary,
                    );
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          // User stats
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.examsTaken,
                      '$_totalExamsTaken',
                      Icons.quiz,
                      AppColors.primary,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.averageScore,
                      '${_averageScore.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      AppColors.success,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.studyStreak,
                      l10n.studyStreakDays(_studyStreak),
                      Icons.local_fire_department,
                      AppColors.warning,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildStatCard(
                      l10n.achievements,
                      '$_achievements',
                      Icons.emoji_events,
                      AppColors.secondary,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Map locale code to exam type
  String _mapLocaleToExamType(String localeCode) {
    switch (localeCode.toLowerCase()) {
      case 'rw':
        return 'kinyarwanda';
      case 'en':
        return 'english';
      case 'fr':
        return 'french';
      default:
        return 'kinyarwanda'; // Default to kinyarwanda
    }
  }

  Widget _buildAvailableServicesCard() {
    final courseState = ref.watch(courseProvider);
    final currentLocale = ref.watch(localeProvider);
    final selectedExamType = _mapLocaleToExamType(currentLocale.languageCode);

    // Get exam count (works offline with cached data)
    final activeExams = _exams.where((exam) {
      if (!exam.isActive) return false;
      String type = exam.examType?.toLowerCase() ?? 'english';
      if (type == 'unknown' || exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        } else {
          type = 'english';
        }
      }
      return type == selectedExamType.toLowerCase();
    }).toList();

    final examCount = activeExams.length;

    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.availableServices,
              style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
            ),

            // First row: Exams and Courses
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.quiz,
                    iconColor: AppColors.primary,
                    imageUrl: '${AppConstants.baseUrlImage}exam14.png',
                    title: l10n.exams,
                    subtitle: examCount > 0
                        ? '$examCount ${examCount == 1 ? l10n.exam : l10n.exams}'
                        : l10n.practiceExams,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const exams_screen.AvailableExamsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.school,
                    iconColor: AppColors.success,
                    imageUrl:
                        '${AppConstants.imageBaseUrl}ishuri_online.png', // Replace with actual course icon image
                    title: l10n.courses,
                    subtitle: courseState.isLoading
                        ? l10n.loading
                        : courseState.courses.isEmpty
                        ? l10n.noCoursesAvailable
                        : '${courseState.courses.length} ${l10n.courses}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const courses_list_screen.CourseListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Second row: WhatsApp Group and Share App
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.chat,
                    iconColor: Colors.green,
                    title: l10n.joinWhatsAppGroup,
                    subtitle: l10n.connectWithLearners,
                    onTap: () => _joinWhatsAppGroup(),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.share,
                    iconColor: AppColors.warning,

                    title: l10n.shareApp,
                    subtitle: l10n.shareWithFriends,
                    onTap: () => _shareApp(),
                  ),
                ),
              ],
            ),

            // Third row: Gazette and Road Signs
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.description,
                    iconColor: AppColors.primary,
                    imageUrl:
                        '${AppConstants.imageBaseUrl}official_gazette.png', // Replace with actual gazette icon image
                    title: l10n.officialGazette,
                    subtitle: l10n.officialGazetteDescription,
                    onTap: () => _openGazette(context),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.traffic,
                    iconColor: AppColors.success,
                    imageUrl:
                        '${AppConstants.imageBaseUrl}official_roads_signs.png', // Replace with actual road signs icon image
                    title: l10n.roadSigns,
                    subtitle: l10n.roadSignsDescription,
                    onTap: () => _openRoadSigns(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required Color iconColor,
    String? imageUrl,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Pre-cache image if provided
    if (imageUrl != null) {
      ImageCacheService.instance.cacheImage(imageUrl);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150
            .h, // Fixed height to ensure consistent card sizes and larger images
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Use image from server if provided, otherwise use icon
            if (imageUrl != null && imageUrl.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: AppColors.grey50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: FutureBuilder<String>(
                      future: ImageCacheService.instance.getImagePath(imageUrl),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            color: AppColors.grey100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        final imagePath = snapshot.data ?? '';
                        if (imagePath.isEmpty) {
                          return Container(
                            color: AppColors.grey100,
                            child: Icon(icon, size: 40.sp, color: iconColor),
                          );
                        }

                        // Check if it's a local file path or a network URL
                        final isLocalFile =
                            imagePath.startsWith('/') &&
                            !imagePath.startsWith('http');

                        if (isLocalFile) {
                          // Use Image.file for local cached files
                          return Image.file(
                            File(imagePath),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                '❌ Error loading local image: $imagePath - $error',
                              );
                              return Container(
                                color: AppColors.grey100,
                                child: Icon(
                                  icon,
                                  size: 40.sp,
                                  color: iconColor,
                                ),
                              );
                            },
                          );
                        }

                        return Image.network(
                          imagePath,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              '❌ Error loading network image: $imagePath - $error',
                            );
                            return Container(
                              color: AppColors.grey100,
                              child: Icon(icon, size: 40.sp, color: iconColor),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.grey100,
                              child: Icon(icon, size: 40.sp, color: iconColor),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: AppColors.grey100,
                  ),
                  child: Icon(icon, size: 40.sp, color: iconColor),
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: AppColors.grey800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.sp,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGazette(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenOfficialGazetteScreen()),
    );
  }

  Future<void> _openRoadSigns(BuildContext context) async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RoadSignsPdfScreen()));
  }

  Future<void> _joinWhatsAppGroup() async {
    // WhatsApp group invite link - if user doesn't have WhatsApp, it will prompt to download
    const whatsappGroupLink =
        'https://chat.whatsapp.com/JHfdbKSYVFz1s5jlTKfpcm?mode=wwt';
    final Uri whatsappUri = Uri.parse(whatsappGroupLink);

    debugPrint('🔍 WhatsApp Group URL: $whatsappUri');

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      debugPrint('✅ WhatsApp group link launched successfully');
    } catch (e) {
      debugPrint('❌ WhatsApp group link launch failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.whatsappNotAvailableTryTheseAlternatives),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

    return const exams_screen.AvailableExamsScreen();
  }

  Widget _buildProgressTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isUser = user?.role == 'USER';

    if (isUser) {
      return progress_screen.ProgressScreen(isVisible: _currentIndex == 2);
    }
    return const UserManagementScreen();
  }

  Widget _buildProfileTab() {
    //disable back button when user are on dashboard screen
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n.profile,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 20.sp,
                color: AppColors.white,
              ),
            );
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),

            // Settings Options
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Column(
                  children: [
                    _buildSettingsOption(
                      l10n.viewProfile,
                      l10n.viewAndManageYourProfileInformation,
                      Icons.person_outline,
                      () {
                        Navigator.pushNamed(context, '/view-profile');
                      },
                    ),

                    // _buildSettingsOption(
                    //   l10n.notifications,
                    //   l10n.manageYourNotificationPreferences,
                    //   Icons.notifications,
                    //   () {
                    //     Navigator.pushNamed(context, '/notifications');
                    //   },
                    // ),

                    // _buildSettingsOption(
                    //   l10n.studyReminders,
                    //   l10n.setUpStudyReminders,
                    //   Icons.schedule,
                    //   () {
                    //     Navigator.pushNamed(context, '/study-reminders');
                    //   },
                    // ),
                    _buildSettingsOption(
                      l10n.aboutApp,
                      l10n.learnMoreAboutThisApplication,
                      Icons.info_outline,
                      () {
                        Navigator.pushNamed(context, '/about-app');
                      },
                    ),

                    _buildSettingsOption(
                      l10n.privacyPolicyLabel,
                      l10n.readOurPrivacyPolicy,
                      Icons.privacy_tip_outlined,
                      () {
                        Navigator.pushNamed(context, '/privacy-policy');
                      },
                    ),

                    _buildSettingsOption(
                      l10n.termsConditionsLabel,
                      l10n.readOurTermsAndConditions,
                      Icons.description_outlined,
                      () {
                        Navigator.pushNamed(context, '/terms-conditions');
                      },
                    ),

                    _buildSettingsOption(
                      l10n.shareApp,
                      l10n.shareThisAppWithFriendsAndFamily,
                      Icons.share,
                      () {
                        _shareApp();
                      },
                    ),

                    _buildSettingsOption(
                      l10n.helpSupport,
                      l10n.getHelpAndContactSupport,
                      Icons.help,
                      () {
                        Navigator.pushNamed(context, '/help-support');
                      },
                    ),

                    _buildSettingsOption(
                      l10n.deleteAccount,
                      l10n.permanentlyDeleteYourAccount,
                      Icons.delete_forever,
                      () {
                        Navigator.pushNamed(context, '/delete-account');
                      },
                      isDestructive: true,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 24.h),

            // Logout Button
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return CustomButton(
                  text: l10n.logout,
                  onPressed: () async {
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: AppColors.error,
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(l10n.logout),
                            ],
                          ),
                          content: Text(
                            l10n.areYouSureYouWantToLogout,
                            style: AppTextStyles.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.white,
                              ),
                              child: Text(l10n.logout),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldLogout == true && mounted) {
                      // OPTIMIZATION: Clear local state immediately and navigate
                      // Don't wait for API logout - it can happen in background
                      // This makes logout feel instant

                      // Clear local auth state immediately (non-blocking)
                      ref.read(authProvider.notifier).logout().catchError((e) {
                        debugPrint('⚠️ Background logout failed: $e');
                        // Ignore errors - local logout already happened
                      });

                      // Navigate immediately without waiting
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          this.context,
                          '/login',
                          (route) => false, // Remove all previous routes
                        );
                      }
                    }
                  },
                  backgroundColor: AppColors.error,
                  width: double.infinity,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp() async {
    try {
      final l10n = AppLocalizations.of(context);
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      const playStoreLink =
          'https://play.google.com/store/apps/details?id=com.trafficrules.master';

      // Get localized share message and replace placeholders
      final shareText = l10n.shareAppMessage
          .replaceAll('{appName}', appName)
          .replaceAll('{version}', version)
          .replaceAll('{buildNumber}', buildNumber)
          .replaceAll('{playStoreLink}', playStoreLink);

      await Share.share(shareText, subject: l10n.shareAppSubject);
    } catch (e) {
      debugPrint('Error sharing app: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareFailed),
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
