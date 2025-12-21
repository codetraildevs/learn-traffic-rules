import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/screens/user/available_exams_screen.dart';
import '../../models/exam_result_model.dart';
import '../../services/exam_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/network_service.dart';
import '../../services/exam_sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with WidgetsBindingObserver {
  final ExamService _examService = ExamService();
  final OfflineExamService _offlineService = OfflineExamService();
  final NetworkService _networkService = NetworkService();
  final ExamSyncService _syncService = ExamSyncService();
  List<ExamResultData> _examResults = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static const MethodChannel _securityChannel = MethodChannel(
    'com.trafficrules.master/security',
  );

  // Track app lifecycle to prevent unnecessary refreshes on screenshots
  DateTime? _lastBackgroundTime;
  static const _minBackgroundDuration = Duration(seconds: 3);

  Future<void> _disableScreenshots() async {
    if (Platform.isAndroid) {
      try {
        await _securityChannel.invokeMethod('disableScreenshots');
        debugPrint('🔒 Security: Screenshots disabled for detailed answers');
      } catch (e) {
        debugPrint('🔒 Security: Failed to disable screenshots: $e');
      }
    }
  }

  Future<void> _enableScreenshots() async {
    if (Platform.isAndroid) {
      try {
        await _securityChannel.invokeMethod('enableScreenshots');
        debugPrint('🔒 Security: Screenshots enabled after detailed answers');
      } catch (e) {
        debugPrint('🔒 Security: Failed to enable screenshots: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExamResults();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    // Listen for connectivity changes
    _connectivitySubscription = _networkService.connectivityStream.listen((
      ConnectivityResult result,
    ) async {
      if (result != ConnectivityResult.none) {
        // Internet is back, check if we have unsynced results
        final hasInternet = await _networkService.hasInternetConnection();
        if (hasInternet && mounted) {
          debugPrint('🌐 Internet connection restored, syncing results...');
          // Sync unsynced results
          _syncService
              .syncExamResults()
              .then((_) {
                debugPrint('✅ Results synced successfully');
                // Reload results to show updated data
                if (mounted) {
                  _loadExamResults();
                }
              })
              .catchError((e) {
                debugPrint('⚠️ Failed to sync results: $e');
              });
        }
      } else {
        debugPrint('🌐 Internet connection lost');
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
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
          // When app resumes, check connectivity and sync if needed
          _networkService.hasInternetConnection().then((hasInternet) {
            if (hasInternet && mounted) {
              debugPrint(
                '🔄 App resumed with internet, checking for unsynced results...',
              );
              // Sync unsynced results
              _syncService
                  .syncExamResults()
                  .then((_) {
                    debugPrint('✅ Results synced after app resume');
                    // Reload results to show updated data
                    if (mounted) {
                      _loadExamResults();
                    }
                  })
                  .catchError((e) {
                    debugPrint('⚠️ Failed to sync results on resume: $e');
                  });
            }
          });
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

  Future<void> _loadExamResults() async {
    try {
      debugPrint('🔄 Loading exam results...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();

      setState(() {
        _isOffline = !hasInternet;
      });

      List<ExamResultData> results = [];

      if (hasInternet) {
        // Online: Try to load from API first
        try {
          debugPrint('🌐 Online: Loading results from API...');
          results = await _examService.getUserExamResults();
          debugPrint(
            '📊 Exam results loaded from API: ${results.length} results',
          );

          // Also get offline results to merge (unsynced results)
          final offlineResults = await _offlineService.getAllResults();
          final unsyncedResults = offlineResults
              .where((r) => r['synced'] == false)
              .toList();

          if (unsyncedResults.isNotEmpty) {
            debugPrint(
              '📱 Found ${unsyncedResults.length} unsynced results, syncing...',
            );
            // Try to sync unsynced results in background
            _syncService.syncExamResults().catchError((e) {
              debugPrint('⚠️ Failed to sync results: $e');
            });
          }

          // Merge offline unsynced results with online results
          // Convert offline results to ExamResultData
          final authState = ref.read(authProvider);
          final userId = authState.user?.id ?? 'offline-user';

          for (final offlineResult in unsyncedResults) {
            // Check if this result is already in the online results
            final existsOnline = results.any(
              (r) =>
                  r.examId == offlineResult['examId'] as String &&
                  r.submittedAt.toIso8601String() ==
                      offlineResult['completedAt'] as String,
            );

            if (!existsOnline) {
              // Add offline result to the list
              results.add(
                ExamResultData(
                  id: offlineResult['id'].toString(),
                  examId: offlineResult['examId'] as String,
                  userId: userId,
                  score: (offlineResult['score'] as double).toInt(),
                  totalQuestions: offlineResult['totalQuestions'] as int,
                  correctAnswers: offlineResult['correctAnswers'] as int,
                  timeSpent: offlineResult['timeSpent'] as int,
                  passed: offlineResult['passed'] as bool,
                  isFreeExam: offlineResult['isFreeExam'] as bool,
                  submittedAt: DateTime.parse(
                    offlineResult['completedAt'] as String,
                  ),
                ),
              );
            }
          }

          // Sort by submission time (newest first)
          results.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        } catch (e) {
          debugPrint('❌ Failed to load from API: $e');
          // Fallback to offline data
          results = await _loadOfflineResults();
        }
      } else {
        // Offline: Load from local database
        debugPrint('📱 Offline: Loading results from local storage...');
        results = await _loadOfflineResults();
      }

      debugPrint('📊 Total exam results loaded: ${results.length} results');
      debugPrint(
        '   Results: ${results.map((r) => '${r.examId}: ${r.score}%').join(', ')}',
      );

      setState(() {
        _examResults = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading exam results: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<ExamResultData>> _loadOfflineResults() async {
    try {
      final offlineResults = await _offlineService.getAllResults();
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? 'offline-user';

      final results = offlineResults.map((r) {
        return ExamResultData(
          id: r['id'].toString(),
          examId: r['examId'] as String,
          userId: userId,
          score: (r['score'] as double).toInt(),
          totalQuestions: r['totalQuestions'] as int,
          correctAnswers: r['correctAnswers'] as int,
          timeSpent: r['timeSpent'] as int,
          passed: r['passed'] as bool,
          isFreeExam: r['isFreeExam'] as bool,
          submittedAt: DateTime.parse(r['completedAt'] as String),
        );
      }).toList();

      // Sort by submission time (newest first)
      results.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      debugPrint('📱 Loaded ${results.length} results from offline storage');
      return results;
    } catch (e) {
      debugPrint('❌ Error loading offline results: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          l10n.myProgress,
          style: AppTextStyles.heading2.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null && _examResults.isEmpty
          ? _buildErrorView()
          : _examResults.isEmpty
          ? _buildEmptyView()
          : _buildProgressView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200.h,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.errorLoadingProgress,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _error ?? l10n.unknownErrorOccurred,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isOffline) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: AppColors.warning,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              l10n.offlineModeShowingCachedResultsOnly,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.grey600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadExamResults,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to exams tab
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AvailableExamsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz),
                          label: Text(l10n.startExam),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200.h,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress tracking icon
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 50.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    Text(
                      l10n.progressTracking,
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey800,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Text(
                      l10n.yourProgressAndAnalyticsWillAppearHere,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),

                    Text(
                      l10n.takeYourFirstExamToStartTrackingYourPerformance,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.grey500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to exams tab
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AvailableExamsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.quiz),
                        label: Text(l10n.startExam),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
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
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: AppColors.warning, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlineMode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.showingCachedResultsResultsWillSyncWhenInternetIsAvailable,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView() {
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline/Sync Status Banner
            if (_isOffline) ...[_buildOfflineBanner(), SizedBox(height: 16.h)],
            // Performance Overview
            _buildPerformanceOverview(),
            SizedBox(height: 24.h),

            // Recent Results
            _buildRecentResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final l10n = AppLocalizations.of(context);
    // Count unique exams (not total attempts)
    final uniqueExamIds = _examResults.map((result) => result.examId).toSet();
    final totalExams = uniqueExamIds.length;

    // Count passed exams (unique exams that have at least one passed attempt)
    final passedExamIds = _examResults
        .where((result) => result.passed)
        .map((result) => result.examId)
        .toSet();
    final passedExams = passedExamIds.length;

    final totalTimeSpent = _examResults.isNotEmpty
        ? _examResults.map((result) => result.timeSpent).reduce((a, b) => a + b)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourStatistics,
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.quiz,
                label: l10n.totalExams,
                value: '$totalExams',
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                label: l10n.passed,
                value: '$passedExams',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                label: l10n.averageScore,
                value: '${_calculateAverageScore().toStringAsFixed(1)}%',
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: l10n.totalTime,
                value: _formatTime(totalTimeSpent),
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentResults,
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: 16.h),

        ..._examResults.take(10).map((result) => _buildResultCard(result)),
      ],
    );
  }

  Widget _buildResultCard(ExamResultData result) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: InkWell(
        onTap: () => _viewExamResult(result),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: result.passed
                          ? AppColors.success
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${result.score}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      result.exam?.title ?? l10n.examResult,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14.sp,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    l10n.correctAnswersCount(
                      result.correctAnswers,
                      result.questionResults?.length ?? result.totalQuestions,
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    Icons.timer_outlined,
                    size: 14.sp,
                    color: AppColors.grey600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatTime(result.timeSpent),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12.sp,
                    color: AppColors.grey500,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDateTime(result.submittedAt),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        result.passed ? l10n.passed : l10n.failed,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: result.passed
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: AppColors.grey400,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewExamResult(ExamResultData result) async {
    // Disable screenshots before showing detailed answers
    await _disableScreenshots();

    // Show detailed exam result with question-by-question answers
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureDetailedAnswersModal(
        examResult: result,
        onClose: () async {
          // Re-enable screenshots when closing
          await _enableScreenshots();
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  double _calculateAverageScore() {
    if (_examResults.isEmpty) return 0.0;
    return _examResults.map((result) => result.score).reduce((a, b) => a + b) /
        _examResults.length;
  }
}

// Secure modal widget that prevents screenshots
class _SecureDetailedAnswersModal extends StatefulWidget {
  final ExamResultData examResult;
  final VoidCallback onClose;

  const _SecureDetailedAnswersModal({
    required this.examResult,
    required this.onClose,
  });

  @override
  State<_SecureDetailedAnswersModal> createState() =>
      _SecureDetailedAnswersModalState();
}

class _SecureDetailedAnswersModalState
    extends State<_SecureDetailedAnswersModal> {
  static const MethodChannel _securityChannel = MethodChannel(
    'com.trafficrules.master/security',
  );

  @override
  void initState() {
    super.initState();
    _disableScreenshots();
  }

  @override
  void dispose() {
    _enableScreenshots();
    widget.onClose();
    super.dispose();
  }

  Future<void> _disableScreenshots() async {
    if (Platform.isAndroid) {
      try {
        await _securityChannel.invokeMethod('disableScreenshots');
        debugPrint(
          '🔒 Security: Screenshots disabled for detailed answers modal',
        );
      } catch (e) {
        debugPrint('🔒 Security: Failed to disable screenshots: $e');
      }
    }
  }

  Future<void> _enableScreenshots() async {
    if (Platform.isAndroid) {
      try {
        await _securityChannel.invokeMethod('enableScreenshots');
        debugPrint(
          '🔒 Security: Screenshots enabled after detailed answers modal',
        );
      } catch (e) {
        debugPrint('🔒 Security: Failed to enable screenshots: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header with security warning
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.security, color: AppColors.error, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          l10n.secureView,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.grey600),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),
                  Text(
                    l10n.detailedAnswersFor(
                      widget.examResult.exam?.title ?? l10n.exam,
                    ),
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey800,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: AppColors.error,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            l10n.screenshotsAreDisabledToProtectAnswerIntegrity,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child:
                  widget.examResult.questionResults == null ||
                      widget.examResult.questionResults!.isEmpty
                  ? _buildSecureNoResultsView()
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: widget.examResult.questionResults!.length,
                      itemBuilder: (context, index) {
                        final questionResult =
                            widget.examResult.questionResults![index];
                        return _buildSecureQuestionResultCard(
                          questionResult,
                          index + 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureNoResultsView() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              l10n.noDetailedResultsAvailable,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.grey600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.questionByQuestionResultsNotAvailable,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14.sp,
                color: AppColors.grey500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, size: 20.sp),
              label: Text(l10n.close),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey600,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureQuestionResultCard(
    QuestionResult questionResult,
    int questionNumber,
  ) {
    final l10n = AppLocalizations.of(context);
    final isCorrect = questionResult.isCorrect;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCorrect ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                isCorrect ? l10n.correct : l10n.incorrect,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isCorrect ? AppColors.success : AppColors.error,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${questionResult.points} point${questionResult.points > 1 ? 's' : ''}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey600,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Question text
          if (questionResult.questionText != null &&
              questionResult.questionText!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question:',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    questionResult.questionText!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (questionResult.questionText != null &&
              questionResult.questionText!.isNotEmpty)
            SizedBox(height: 12.h),

          // All options
          if (questionResult.options != null &&
              questionResult.options!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.grey300.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Options:',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...questionResult.options!.entries.map((entry) {
                    final optionKey = entry.key;
                    final optionText = entry.value;
                    final isUserAnswer =
                        questionResult.userAnswer == optionText;
                    final isCorrectAnswer =
                        questionResult.correctAnswer == optionText;

                    return Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: isCorrectAnswer
                            ? AppColors.success.withValues(alpha: 0.1)
                            : isUserAnswer && !isCorrectAnswer
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isCorrectAnswer
                              ? AppColors.success
                              : isUserAnswer && !isCorrectAnswer
                              ? AppColors.error
                              : AppColors.grey300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrectAnswer
                                  ? AppColors.success
                                  : isUserAnswer && !isCorrectAnswer
                                  ? AppColors.error
                                  : AppColors.grey300,
                            ),
                            child: Center(
                              child: Text(
                                optionKey.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      isCorrectAnswer ||
                                          (isUserAnswer && !isCorrectAnswer)
                                      ? AppColors.white
                                      : AppColors.grey600,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13.sp,
                                color: isCorrectAnswer
                                    ? AppColors.success
                                    : isUserAnswer && !isCorrectAnswer
                                    ? AppColors.error
                                    : AppColors.grey700,
                                fontWeight:
                                    isCorrectAnswer ||
                                        (isUserAnswer && !isCorrectAnswer)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCorrectAnswer)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16.sp,
                            ),
                          if (isUserAnswer && !isCorrectAnswer)
                            Icon(
                              Icons.cancel,
                              color: AppColors.error,
                              size: 16.sp,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
