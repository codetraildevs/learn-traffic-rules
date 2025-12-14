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
import 'package:learn_traffic_rules/screens/user/exam_progress_screen.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/network_service.dart';
import '../../services/exam_sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'exam_taking_screen.dart';

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
    if (state == AppLifecycleState.resumed) {
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.myProgress,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: const Color(0xFF2E7D32),
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
                  Icon(Icons.error_outline, size: 80.w, color: Colors.red),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.errorLoadingProgress,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _error ?? l10n.unknownErrorOccurred,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (_isOffline) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.orange[700],
                            size: 16.w,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              l10n.offlineModeShowingCachedResultsOnly,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[700],
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
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
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
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
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
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: const Color(0xFF2E7D32),
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
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(60.r),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 60.w,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    Text(
                      l10n.progressTracking,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Text(
                      l10n.yourProgressAndAnalyticsWillAppearHere,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),

                    Text(
                      l10n.takeYourFirstExamToStartTrackingYourPerformance,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    // Features preview
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.whatYouWillSeeHere,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16.h),

                          _buildFeaturePreview(
                            icon: Icons.trending_up,
                            title: l10n.performanceTrends,
                            description: l10n.trackYourImprovementOverTime,
                          ),
                          SizedBox(height: 12.h),

                          _buildFeaturePreview(
                            icon: Icons.analytics,
                            title: l10n.detailedAnalytics,
                            description: l10n.seeYourStrengthsAndWeaknesses,
                          ),
                          SizedBox(height: 12.h),

                          _buildFeaturePreview(
                            icon: Icons.lightbulb,
                            title: l10n.studyRecommendations,
                            description: l10n.getPersonalizedStudyTips,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
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
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadExamResults,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
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
      ),
    );
  }

  Widget _buildOfflineBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange[700], size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlineMode,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                Text(
                  l10n.showingCachedResultsResultsWillSyncWhenInternetIsAvailable,
                  style: TextStyle(fontSize: 12.sp, color: Colors.orange[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressView() {
    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline/Sync Status Banner
            if (_isOffline) _buildOfflineBanner(),
            SizedBox(height: _isOffline ? 16.h : 0),
            // Performance Overview
            _buildPerformanceOverview(),
            SizedBox(height: 24.h),

            // Areas of Improvement
            _buildAreasOfImprovement(),
            SizedBox(height: 24.h),

            // Performance Trends
            _buildPerformanceTrends(),
            SizedBox(height: 24.h),

            // Category Performance
            _buildCategoryPerformance(),
            SizedBox(height: 24.h),

            // Study Recommendations
            _buildStudyRecommendations(),
            SizedBox(height: 24.h),

            // Recent Results
            _buildRecentResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final l10n = AppLocalizations.of(context)!;
    // Count unique exams (not total attempts)
    final uniqueExamIds = _examResults.map((result) => result.examId).toSet();
    final totalExams = uniqueExamIds.length;

    // Count passed exams (unique exams that have at least one passed attempt)
    final passedExamIds = _examResults
        .where((result) => result.passed)
        .map((result) => result.examId)
        .toSet();
    final passedExams = passedExamIds.length;

    // final averageScore = _examResults.isNotEmpty
    //     ? _examResults.map((result) => result.score).reduce((a, b) => a + b) /
    //           _examResults.length
    //     : 0.0;
    final totalTimeSpent = _examResults.isNotEmpty
        ? _examResults.map((result) => result.timeSpent).reduce((a, b) => a + b)
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourStatistics,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 20.h),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.quiz,
                  label: l10n.totalExams,
                  value: '$totalExams',
                  color: const Color(0xFF2196F3),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: l10n.passed,
                  value: '$passedExams',
                  color: const Color(0xFF4CAF50),
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
                  color: const Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  label: l10n.totalTime,
                  value: _formatTime(totalTimeSpent),
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentResults,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 16.h),

        ..._examResults.take(10).map((result) => _buildResultCard(result)),
      ],
    );
  }

  Widget _buildResultCard(ExamResultData result) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewExamResult(result),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Score Circle
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.passed
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFFF5722).withValues(alpha: 0.1),
                  border: Border.all(
                    color: result.passed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5722),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${result.score}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: result.passed
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Exam Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.exam?.title ?? l10n.examResult,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.correctAnswersCount(
                        result.correctAnswers,
                        result.questionResults?.length ?? 0,
                      ),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDateTime(result.submittedAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Status and Action
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: result.passed
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      result.passed ? l10n.passed : l10n.failed,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.w,
                    color: Colors.grey[400],
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

  // ==================== NEW COMPREHENSIVE ANALYTICS METHODS ====================

  Widget _buildAreasOfImprovement() {
    final l10n = AppLocalizations.of(context)!;
    if (_examResults.isEmpty) return const SizedBox.shrink();

    // Get unique failed results (most recent attempt for each exam)
    final failedResults = <String, ExamResultData>{};
    for (final result in _examResults.where((result) => !result.passed)) {
      if (!failedResults.containsKey(result.examId) ||
          result.submittedAt.isAfter(
            failedResults[result.examId]!.submittedAt,
          )) {
        failedResults[result.examId] = result;
      }
    }
    final uniqueFailedResults = failedResults.values.toList();

    // Get unique low score results (most recent attempt for each exam)
    final lowScoreResults = <String, ExamResultData>{};
    for (final result in _examResults.where((result) => result.score < 70)) {
      if (!lowScoreResults.containsKey(result.examId) ||
          result.submittedAt.isAfter(
            lowScoreResults[result.examId]!.submittedAt,
          )) {
        lowScoreResults[result.examId] = result;
      }
    }
    final uniqueLowScoreResults = lowScoreResults.values.toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.red[600], size: 24.w),
              SizedBox(width: 8.w),
              Text(
                l10n.areasOfImprovement,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (uniqueFailedResults.isNotEmpty) ...[
            _buildImprovementCard(
              icon: Icons.warning,
              title: l10n.failedExamsTitle,
              description: l10n.youHaveFailedExams(
                uniqueFailedResults.length,
                uniqueFailedResults.length == 1 ? '' : 's',
              ),
              color: Colors.red,
              action: l10n.retakeFailedExams,
              onTap: () => _showFailedExams(uniqueFailedResults),
            ),
            SizedBox(height: 12.h),
          ],

          if (uniqueLowScoreResults.isNotEmpty) ...[
            _buildImprovementCard(
              icon: Icons.speed,
              title: l10n.lowPerformance,
              description: l10n.examsWithLowScores(
                uniqueLowScoreResults.length,
                uniqueLowScoreResults.length == 1 ? '' : 's',
              ),
              color: Colors.orange,
              action: l10n.reviewTopics,
              onTap: () => _showLowScoreExams(uniqueLowScoreResults),
            ),
            SizedBox(height: 12.h),
          ],

          _buildImprovementCard(
            icon: Icons.analytics,
            title: l10n.studyStrategy,
            description: l10n.focusOnConsistentPractice,
            color: Colors.blue,
            action: l10n.studyTips,
            onTap: _showStudyTips,
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              action,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    final l10n = AppLocalizations.of(context)!;
    if (_examResults.length < 2) return const SizedBox.shrink();

    // Sort results by date
    final sortedResults = List<ExamResultData>.from(_examResults)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

    final recentScores = sortedResults
        .take(5)
        .map((result) => result.score)
        .toList();
    final isImproving =
        recentScores.length >= 2 && recentScores.last > recentScores.first;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImproving ? Icons.trending_up : Icons.trending_down,
                color: isImproving ? Colors.green : Colors.red,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.performanceTrend,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isImproving ? Colors.green[600] : Colors.red[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Trend visualization
          SizedBox(
            height: 100.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentScores.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value;
                final height = (score / 100) * 80.h;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20.w,
                      height: height,
                      decoration: BoxDecoration(
                        color: isImproving ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${index + 1}',
                      style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 12.h),
          Text(
            isImproving
                ? l10n.greatJobPerformanceImproving
                : l10n.performanceNeedsAttention,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    final l10n = AppLocalizations.of(context)!;
    // Get unique results first (most recent attempt for each exam)
    final uniqueResults = <String, ExamResultData>{};
    for (final result in _examResults) {
      if (!uniqueResults.containsKey(result.examId) ||
          result.submittedAt.isAfter(
            uniqueResults[result.examId]!.submittedAt,
          )) {
        uniqueResults[result.examId] = result;
      }
    }

    // Group unique results by category
    final categories = <String, List<ExamResultData>>{};

    for (final result in uniqueResults.values) {
      // Use exam category from the result, or determine from exam title
      String category = result.exam?.category ?? l10n.trafficRules;

      // If no category in exam data, try to determine from title
      if (category == l10n.trafficRules || category.isEmpty) {
        final title = result.exam?.title ?? '';
        if (title.toLowerCase().contains('sign') ||
            title.toLowerCase().contains('signal')) {
          category = l10n.roadSigns;
        } else if (title.toLowerCase().contains('safety') ||
            title.toLowerCase().contains('maintenance')) {
          category = l10n.safety;
        } else if (title.toLowerCase().contains('environment') ||
            title.toLowerCase().contains('eco')) {
          category = l10n.environment;
        } else {
          category = l10n.trafficRules;
        }
      }

      categories[category] = categories[category] ?? [];
      categories[category]!.add(result);
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.blue[600], size: 24.w),
              SizedBox(width: 8.w),
              Text(
                l10n.categoryPerformance,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          ...categories.entries.map((entry) {
            final category = entry.key;
            final results = entry.value;
            final avgScore =
                results.map((r) => r.score).reduce((a, b) => a + b) /
                results.length;
            final passedCount = results.where((r) => r.passed).length;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          l10n.examsCountWithPassed(
                            results.length,
                            results.length == 1 ? '' : 's',
                            passedCount,
                          ),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: avgScore >= 70 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${avgScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudyRecommendations() {
    final totalExams = _examResults.length;
    final passedExams = _examResults.where((result) => result.passed).length;
    final averageScore = totalExams > 0
        ? _examResults.map((result) => result.score).reduce((a, b) => a + b) /
              totalExams
        : 0.0;

    List<String> recommendations = [];

    final l10n = AppLocalizations.of(context)!;
    if (totalExams < 3) {
      recommendations.add(l10n.takeMorePracticeExams);
    }

    if (averageScore < 70) {
      recommendations.add(l10n.focusOnUnderstandingMaterial);
    }

    if (passedExams < totalExams * 0.7) {
      recommendations.add(l10n.reviewFailedExamTopics);
    }

    if (averageScore >= 80) {
      recommendations.add(l10n.excellentPerformanceConsiderAdvanced);
    }

    if (recommendations.isEmpty) {
      recommendations.add(l10n.keepPracticingRegularly);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600], size: 24.w),
              SizedBox(width: 8.w),
              Text(
                l10n.studyRecommendations,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          ...recommendations.map(
            (recommendation) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.amber[600],
                    size: 16.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for improvement actions
  void _showFailedExams(List<ExamResultData> failedResults) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.failedExams(failedResults.length)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: failedResults
                .map(
                  (result) => ListTile(
                    title: Text(
                      result.exam?.title ??
                          '${l10n.exam} ${failedResults.indexOf(result) + 1}',
                    ),
                    subtitle: Text(l10n.latestScore(result.score)),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _retakeExam(result.examId);
                      },
                      child: Text(l10n.retakeExam),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showLowScoreExams(List<ExamResultData> lowScoreResults) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.lowPerformanceExams(lowScoreResults.length)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: lowScoreResults
                .map(
                  (result) => ListTile(
                    title: Text(
                      result.exam?.title ??
                          '${l10n.exam} ${lowScoreResults.indexOf(result) + 1}',
                    ),
                    subtitle: Text(l10n.latestScore(result.score)),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _viewExamResult(result);
                      },
                      child: Text(l10n.viewAnswer),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showStudyTips() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.studyTips),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.studyStrategies),
              SizedBox(height: 8.h),
              Text(l10n.reviewMaterialBeforeTakingExams),
              Text(l10n.takePracticeExamsRegularly),
              Text(l10n.focusOnWeakAreasIdentifiedInResults),
              Text(l10n.useSpacedRepetitionForBetterRetention),
              SizedBox(height: 16.h),
              Text(l10n.examTips),
              SizedBox(height: 8.h),
              Text(l10n.readQuestionsCarefully),
              Text(l10n.eliminateObviouslyWrongAnswers),
              Text(l10n.manageYourTimeEffectively),
              Text(l10n.stayCalmAndFocused),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  void _retakeExam(String examId) async {
    try {
      // Find the exam data for this examId
      final examResult = _examResults.firstWhere(
        (result) => result.examId == examId,
      );

      // Create a proper Exam object from the exam result
      final l10n = AppLocalizations.of(context)!;
      final exam = Exam(
        id: examResult.examId,
        title: examResult.exam?.title ?? l10n.exam,
        description: l10n.retakeThisExam,
        category: examResult.exam?.category ?? 'General',
        difficulty: examResult.exam?.difficulty ?? 'Medium',
        duration: 20,
        passingScore: 60,
        isActive: true,
      );

      // Navigate to exam taking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamTakingScreen(
            exam: exam,
            isFreeExam: true, // Allow retakes for free
            onExamCompleted: (result) {
              // Navigate to exam progress screen to show results
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamProgressScreen(
                    exam: exam,
                    examResult: result,
                    isFreeExam: true,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to retake exam: $e');
      // Show error message
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorCouldNotStartExamRetake),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Header with security warning
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      widget.examResult.passed
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.examResult.exam?.title ?? l10n.examResult,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.scoreWithCorrectCount(
                              widget.examResult.score,
                              widget.examResult.correctAnswers,
                              widget.examResult.questionResults?.length ?? 0,
                            ),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.red[600], size: 16.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          l10n.screenshotsDisabledToProtectIntegrity,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red[700],
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
                    padding: EdgeInsets.all(16.w),
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
    );
  }

  Widget _buildSecureNoResultsView() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            l10n.noDetailedResultsAvailable,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.questionBreakdownNotAvailable,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecureQuestionResultCard(
    QuestionResult questionResult,
    int questionNumber,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: questionResult.isCorrect
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFFF5722).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: questionResult.isCorrect
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFFF5722).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: questionResult.isCorrect
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: questionResult.isCorrect
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      questionResult.isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      questionResult.isCorrect ? l10n.correct : l10n.wrong,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Question text
          if (questionResult.questionText != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                questionResult.questionText!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Question image
          if (questionResult.questionImgUrl != null &&
              questionResult.questionImgUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                '${AppConstants.baseUrlImage}${questionResult.questionImgUrl!}',
                width: double.infinity,
                height: 120.h,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120.h,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 40.sp,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Options
          if (questionResult.options != null) ...[
            ...questionResult.options!.entries.map((entry) {
              final letter = entry.key;
              final optionText = entry.value;
              final isUserAnswer = questionResult.userAnswerLetter == letter;
              final isCorrectAnswer =
                  questionResult.correctAnswerLetter == letter;

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isCorrectAnswer
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : isUserAnswer && !questionResult.isCorrect
                      ? const Color(0xFFFF5722).withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isCorrectAnswer
                        ? const Color(0xFF4CAF50)
                        : isUserAnswer && !questionResult.isCorrect
                        ? const Color(0xFFFF5722)
                        : Colors.grey[300]!,
                    width:
                        isCorrectAnswer ||
                            (isUserAnswer && !questionResult.isCorrect)
                        ? 2
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: isCorrectAnswer
                            ? const Color(0xFF4CAF50)
                            : isUserAnswer && !questionResult.isCorrect
                            ? const Color(0xFFFF5722)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isCorrectAnswer
                              ? const Color(0xFF4CAF50)
                              : isUserAnswer && !questionResult.isCorrect
                              ? const Color(0xFFFF5722)
                              : Colors.grey[700],
                          fontWeight:
                              isCorrectAnswer ||
                                  (isUserAnswer && !questionResult.isCorrect)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrectAnswer) ...[
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF4CAF50),
                        size: 20.sp,
                      ),
                    ] else if (isUserAnswer && !questionResult.isCorrect) ...[
                      Icon(
                        Icons.cancel,
                        color: const Color(0xFFFF5722),
                        size: 20.sp,
                      ),
                    ],
                  ],
                ),
              );
            }),
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }
}
