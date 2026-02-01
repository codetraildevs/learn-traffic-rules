import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart' as question_model;
import '../../services/exam_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/exam_sync_service.dart';
import '../../services/network_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/exam_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/exam_title_mapper.dart';
import 'exam_progress_screen.dart';

class ExamTakingScreen extends ConsumerStatefulWidget {
  final Exam exam;
  final bool isFreeExam;
  final Function(ExamResultData)? onExamCompleted;

  const ExamTakingScreen({
    super.key,
    required this.exam,
    this.isFreeExam = false,
    this.onExamCompleted,
  });

  @override
  ConsumerState<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends ConsumerState<ExamTakingScreen>
    with TickerProviderStateMixin {
  final ExamService _examService = ExamService();
  final OfflineExamService _offlineService = OfflineExamService();
  final ExamSyncService _syncService = ExamSyncService();
  final NetworkService _networkService = NetworkService();

  // Progress saving key
  String get _progressKey => 'exam_progress_${widget.exam.id}';

  // State variables
  List<question_model.Question> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {};
  final Map<String, bool> _showAnswerFeedback =
      {}; // Track if answer feedback should be shown
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  bool _isOffline = false; // Track offline status

  // Security variables
  bool _isAppInBackground = false;
  int _backgroundTime = 0;
  Timer? _backgroundTimer;
  bool _securityWarningShown = false;
  // Removed _screenshotAttempts - not needed for current implementation
  bool _isExamCompleted = false;
  static const MethodChannel _securityChannel = MethodChannel(
    'com.trafficrules.master/security',
  );

  // Timer
  Timer? _timer;
  int _timeRemaining = 0;
  bool _isTimeUp = false;

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _questionController;
  late AnimationController _timerController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _questionAnimation;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSecurity();
    _loadQuestions();
  }

  void _initializeSecurity() {
    _disableScreenshots();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _questionAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _questionController,
            curve: Curves.easeOutCubic,
          ),
        );
    _timerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.easeInOut),
    );
  }

  Future<void> _disableScreenshots() async {
    try {
      await _securityChannel.invokeMethod('disableScreenshots');
      debugPrint('🔒 Security: Screenshots disabled for exam taking');
    } catch (e) {
      debugPrint('🔒 Security: Failed to disable screenshots: $e');
    }
  }

  Future<void> _enableScreenshots() async {
    try {
      await _securityChannel.invokeMethod('enableScreenshots');
      debugPrint('🔒 Security: Screenshots enabled after exam');
    } catch (e) {
      debugPrint('🔒 Security: Failed to enable screenshots: $e');
    }
  }

  void _handleAppResumed() {
    if (_isAppInBackground && !_isExamCompleted) {
      _backgroundTime++;
      debugPrint(
        '🔒 Security: App resumed after background, background time: $_backgroundTime seconds',
      );

      if (_backgroundTime > 5) {
        // More than 5 seconds in background
        _showSecurityWarning();
      }
    }
    _isAppInBackground = false;
    _backgroundTimer?.cancel();
  }

  void _handleAppPaused() {
    if (!_isExamCompleted) {
      _isAppInBackground = true;
      // Don't auto-submit when screen locks - just track background time
      // User can resume and continue the exam
      _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _backgroundTime++;
        // Removed auto-submit - allow user to continue exam after screen lock
        debugPrint(
          '🔒 Security: App in background for $_backgroundTime seconds (no auto-submit)',
        );
      });
      debugPrint(
        '🔒 Security: App paused, tracking background time (no auto-submit)',
      );
    }
  }

  void _showSecurityWarning() {
    if (_securityWarningShown || _isExamCompleted) return;

    final l10n = AppLocalizations.of(context);
    _securityWarningShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            Text(l10n.securityAlertTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.examPausedMessage, style: AppTextStyles.bodyMedium),
            SizedBox(height: 12.h),
            Text(
              l10n.examIntegrityNotice,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(l10n.stayInAppRule, style: AppTextStyles.bodySmall),
            Text(l10n.noAppSwitchRule, style: AppTextStyles.bodySmall),
            Text(l10n.noScreenshotRule, style: AppTextStyles.bodySmall),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                l10n.repeatedViolationWarning,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _securityWarningShown = false;
            },
            child: Text(l10n.continueExam),
          ),
        ],
      ),
    );
  }

  // Removed _autoSubmitExam - no longer auto-submitting when screen locks
  // Users can now exit and return to continue the exam

  void _showExitWarning() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.warning, size: 24.sp),
            SizedBox(width: 8.w),
            Text(l10n.exitExam),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.whatWouldYouLikeToDo, style: AppTextStyles.bodyMedium),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                l10n.youCanExitAndReturnLater,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.continueExam),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Exit without submitting - user can return later
              // Save progress before exiting
              _saveExamProgress();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text(l10n.exitWithoutSubmitting),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // OPTIMIZATION: Try offline cache FIRST for instant display
      // This shows questions immediately if available, then updates from API if online
      List<question_model.Question> questions = await _loadOfflineQuestions();

      // Check internet connection in parallel
      final hasInternetFuture = _networkService.hasInternetConnection();

      // If we have cached questions, show them immediately
      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _timeRemaining = widget.exam.duration * 60;
          _isLoading = false;
        });

        // Load progress and start UI in parallel
        _loadExamProgress();
        _startTimer();
        _progressController.forward();
        _questionController.forward();
        _timerController.forward();
      }

      // Check internet connection
      final hasInternet = await hasInternetFuture;

      if (mounted) {
        setState(() {
          _isOffline = !hasInternet;
        });
      }

      if (hasInternet) {
        // Online: Fetch from API (blocking if no cache, background if cache exists)
        if (questions.isEmpty) {
          // No cache - must wait for API
          await _fetchQuestionsFromAPI(false);
        } else {
          // Has cache - fetch in background (non-blocking)
          _fetchQuestionsFromAPI(true).catchError((e) {
            debugPrint('⚠️ Background API fetch failed: $e');
          });
        }
      } else if (questions.isEmpty) {
        // Offline and no cached questions
        setState(() {
          _error =
              'No offline questions available. Please connect to internet to download this exam.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      setState(() {
        _error = 'Failed to load questions: $e';
        _isLoading = false;
      });
    }
  }

  /// Fetch questions from API (runs in background, updates UI if needed)
  Future<void> _fetchQuestionsFromAPI(bool hasCachedQuestions) async {
    try {
      final apiQuestions = await _examService.getQuestionsByExamId(
        widget.exam.id,
        isFreeExam: widget.exam.isFirstTwo ?? false,
        examType: widget.exam.examType,
      );

      if (apiQuestions.isNotEmpty && mounted) {
        // Save to offline storage in background (non-blocking)
        _offlineService.saveExam(widget.exam, apiQuestions).catchError((e) {
          debugPrint('⚠️ Failed to save exam offline: $e');
        });

        // Update UI with fresh questions from API
        setState(() {
          _questions = apiQuestions;
          if (_timeRemaining == 0) {
            _timeRemaining = widget.exam.duration * 60;
          }
        });

        // Reload progress if we updated questions
        if (!hasCachedQuestions) {
          await _loadExamProgress();
          _startTimer();
          _progressController.forward();
          _questionController.forward();
          _timerController.forward();
        }
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      final isPaymentError =
          errorString.contains('403') ||
          errorString.contains('requires payment') ||
          errorString.contains('payment');

      if (isPaymentError) {
        final isFreeExam = widget.exam.isFirstTwo ?? false;
        final authState = ref.read(authProvider);
        final hasAccess = authState.accessPeriod?.hasAccess ?? false;

        if (!isFreeExam || hasAccess) {
          // Not a free exam or user has access - show payment error
          if (mounted && !hasCachedQuestions) {
            setState(() {
              _error =
                  'This exam requires payment. Please upgrade to access all exams.';
              _isLoading = false;
            });
          }
        }
        // If it's a free exam and user doesn't have access, keep using cached questions
      }
      // For other errors, keep using cached questions if available
    }
  }

  Future<List<question_model.Question>> _loadOfflineQuestions() async {
    try {
      final examData = await _offlineService.getExam(widget.exam.id);
      if (examData != null && examData['questions'] != null) {
        final questions =
            examData['questions'] as List<question_model.Question>;
        if (questions.isNotEmpty) {
          return questions;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isTimeUp = true;
    });
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timeUpTitle),
        content: Text(l10n.timeUpMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: Text(l10n.submitExam),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _calculateScore() {
    if (_questions.isEmpty) return 0;
    int correctAnswers = 0;
    for (final question in _questions) {
      final userAnswer = _userAnswers[question.id];
      if (userAnswer == question.correctAnswer) {
        correctAnswers++;
      }
    }
    return ((correctAnswers / _questions.length) * 100).round();
  }

  int _calculateCorrectAnswers() {
    if (_questions.isEmpty) return 0;
    int correctAnswers = 0;
    for (final question in _questions) {
      final userAnswer = _userAnswers[question.id];
      if (userAnswer == question.correctAnswer) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  Color _getTimerColor() {
    final percentage = _timeRemaining / (widget.exam.duration * 60);
    if (percentage > 0.5) return AppColors.success;
    if (percentage > 0.25) return AppColors.warning;
    return AppColors.error;
  }

  void _selectAnswer(String questionId, String answer) {
    debugPrint('🔍 FRONTEND DEBUG - Answer selected:');
    debugPrint('   Question ID: $questionId');
    debugPrint('   Selected Answer: $answer');
    debugPrint('   Current answers: $_userAnswers');

    setState(() {
      _userAnswers[questionId] = answer;
      _showAnswerFeedback[questionId] = true; // Show feedback immediately
    });

    // Save progress after answering
    _saveExamProgress();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _questionController.reset();
      _questionController.forward();
      // Save progress when navigating
      _saveExamProgress();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _questionController.reset();
      _questionController.forward();
      // Save progress when navigating
      _saveExamProgress();
    }
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _isExamCompleted = true; // Mark exam as completed for security
    });

    _timer?.cancel();
    _backgroundTimer?.cancel();

    // Show loading overlay immediately - submit can take 30-60s under load
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    l10n.submittingExamPleaseWait,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Clear saved progress when submitting
    await _clearExamProgress();

    // Re-enable screenshots after exam completion
    if (Platform.isAndroid) {
      await _enableScreenshots();
    }

    try {
      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();
      final timeSpent = (widget.exam.duration * 60) - _timeRemaining;
      final score = _calculateScore();
      final passed = score >= widget.exam.passingScore;
      final submissionTime = DateTime.now(); // Capture submission time

      ExamResultData resultData;

      if (hasInternet) {
        // Online: Submit to server
        try {
          debugPrint('📤 Submitting exam to server...');
          final result = await _examService.submitExamResult(
            examId: widget.exam.id,
            answers: _userAnswers,
            timeSpent: timeSpent,
            isFreeExam: widget.isFreeExam,
          );

          if (result.success && result.data != null) {
            // Use server's submittedAt if available and valid
            resultData = result.data!;

            // Validate server timestamp - compare in UTC to avoid timezone issues
            final nowUtc = DateTime.now().toUtc();
            final serverTimeUtc = resultData.submittedAt.toUtc();
            final timeDiff = serverTimeUtc.difference(nowUtc).abs();

            // Server time should be within 1 hour of current time
            // This accounts for network delay, processing time, and minor timezone differences
            if (timeDiff > const Duration(hours: 1)) {
              debugPrint(
                '⚠️ Server timestamp seems incorrect, using submission time',
              );
              debugPrint('   Server time (UTC): $serverTimeUtc');
              debugPrint('   Current time (UTC): $nowUtc');
              debugPrint('   Difference: ${timeDiff.inMinutes} minutes');

              resultData = ExamResultData(
                id: resultData.id,
                examId: resultData.examId,
                userId: resultData.userId,
                score: resultData.score,
                totalQuestions: resultData.totalQuestions,
                correctAnswers: resultData.correctAnswers,
                timeSpent: resultData.timeSpent,
                passed: resultData.passed,
                isFreeExam: resultData.isFreeExam,
                submittedAt: submissionTime,
                questionResults: resultData.questionResults,
                exam: resultData.exam,
              );
            } else {
              debugPrint(
                '✅ Using server timestamp: ${resultData.submittedAt} (local: ${resultData.submittedAt.toLocal()})',
              );
            }
            debugPrint('✅ Exam submitted successfully to server');
          } else {
            // Server returned error, save offline
            throw Exception('Server submission failed');
          }
        } catch (e) {
          debugPrint('❌ Failed to submit online: $e');
          // Fallback to offline save
          await _offlineService.saveExamResult(
            examId: widget.exam.id,
            score: score.toDouble(),
            totalQuestions: _questions.length,
            correctAnswers: _calculateCorrectAnswers(),
            timeSpent: timeSpent,
            answers: _userAnswers,
            passed: passed,
            isFreeExam: widget.isFreeExam,
          );

          // Create result data from offline save with correct submission time
          final authState = ref.read(authProvider);
          final userId = authState.user?.id ?? 'offline-user';

          resultData = ExamResultData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            examId: widget.exam.id,
            userId: userId,
            score: score,
            totalQuestions: _questions.length,
            correctAnswers: _calculateCorrectAnswers(),
            timeSpent: timeSpent,
            passed: passed,
            isFreeExam: widget.isFreeExam,
            submittedAt: submissionTime, // Use captured submission time
          );

          // Try to sync in background
          _syncService.syncExamResults().catchError((e) {
            debugPrint('⚠️ Failed to sync results: $e');
          });
        }
      } else {
        // Offline: Save offline
        debugPrint('💾 Saving exam result offline...');
        await _offlineService.saveExamResult(
          examId: widget.exam.id,
          score: score.toDouble(),
          totalQuestions: _questions.length,
          correctAnswers: _calculateCorrectAnswers(),
          timeSpent: timeSpent,
          answers: _userAnswers,
          passed: passed,
          isFreeExam: widget.isFreeExam,
        );

        // Create result data from offline save with correct submission time
        final authState = ref.read(authProvider);
        final userId = authState.user?.id ?? 'offline-user';

        resultData = ExamResultData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          examId: widget.exam.id,
          userId: userId,
          score: score,
          totalQuestions: _questions.length,
          correctAnswers: _calculateCorrectAnswers(),
          timeSpent: timeSpent,
          passed: passed,
          isFreeExam: widget.isFreeExam,
          submittedAt: submissionTime, // Use captured submission time
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      final l10n = AppLocalizations.of(context);

      final message = hasInternet
          ? l10n.examSubmittedSuccess
          : l10n.examSavedOffline;

      AppFlashMessage.showSuccess(
        context,
        message,
        description: '${l10n.examScoreDescription} $score%',
      );

      // Use callback if provided, otherwise navigate to progress screen
      if (widget.onExamCompleted != null) {
        widget.onExamCompleted!(resultData);
      } else {
        // Navigate to progress screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamProgressScreen(
              exam: widget.exam,
              examResult: resultData,
              isFreeExam: widget.isFreeExam,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppFlashMessage.showError(
        context,
        l10n.errorSubmittingExam,
        description: e.toString(),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    _timerController.dispose();
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(this));

    // Re-enable screenshots when leaving the exam screen
    if (Platform.isAndroid && !_isExamCompleted) {
      _enableScreenshots();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isExamCompleted,
      onPopInvokedWithResult: (didPop, result) {
        // Prevent back button during exam
        if (!didPop && !_isExamCompleted) {
          _showExitWarning();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        body: _isLoading
            ? _buildLoadingWidget()
            : _error != null
            ? _buildErrorWidget()
            : _isTimeUp
            ? _buildTimeUpWidget()
            : _buildExamContent(),
        floatingActionButton: _isLoading || _error != null || _isTimeUp
            ? null
            : _buildFinishExamFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.loading,
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              l10n.errorLoadingExams,
              style: AppTextStyles.heading2.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: l10n.back,
              onPressed: () => Navigator.pop(context),
              width: 120.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUpWidget() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, size: 80.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              l10n.timeUpTitle,
              style: AppTextStyles.heading2.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.timeUpMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: l10n.submitExam,
              onPressed: _submitExam,
              width: 150.w,
              backgroundColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamContent() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        // Header with timer and progress
        _buildExamHeader(progress),

        // Question content - takes remaining space and scrolls if needed
        Expanded(
          child: SlideTransition(
            position: _questionAnimation,
            child: _buildQuestionContent(currentQuestion),
          ),
        ),

        // Navigation buttons - always visible at bottom
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildExamHeader(double progress) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.of(context).padding.top + 16.h,
        16.w,
        16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exam title and timer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ExamTitleMapper.mapTitle(context, widget.exam.title),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontSize: 18.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${l10n.question} ${_currentQuestionIndex + 1} ${l10n.off} ${_questions.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getTimerColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: _getTimerColor(), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 16.sp, color: _getTimerColor()),
                        SizedBox(width: 6.w),
                        Text(
                          _formatTime(_timeRemaining),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _getTimerColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.progress,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey600,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        '${((_currentQuestionIndex + 1) / _questions.length * 100).round()}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  LinearProgressIndicator(
                    value: _progressAnimation.value * progress,
                    backgroundColor: AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 4.h,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(question_model.Question question) {
    debugPrint("question.questionImgUrl: ${question.questionImgUrl}");
    debugPrint(
      "question.fullquestionimageUrl:${AppConstants.siteBaseUrl}${question.questionImgUrl}",
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Q${_currentQuestionIndex + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        question.questionText,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                if (question.questionImgUrl != null &&
                    question.questionImgUrl!.isNotEmpty) ...[
                  SizedBox(height: 8.h),

                  FutureBuilder<String>(
                    future: _getQuestionImageFuture(
                      question.id.toString(),
                      question.questionImgUrl!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 180.h,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildImageErrorWidget();
                      }

                      final imagePath = snapshot.data!;
                      final isLocalFile = !imagePath.startsWith('http');

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: isLocalFile
                            ? Image.file(
                                File(imagePath),
                                width: double.infinity,
                                height: 200.h,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildImageErrorWidget(),
                              )
                            : (!_isOffline
                                  ? Image.network(
                                      imagePath, // ✅ already resolved
                                      width: double.infinity,
                                      height: 200.h,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _buildImageErrorWidget(),
                                    )
                                  : _buildImageErrorWidget()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          //  SizedBox(height: 24.h),

          // Answer options
          _buildAnswerOptions(question),
        ],
      ),
    );
  }

  final Map<String, Future<String>> _imageFutures = {};

  Future<String> _getQuestionImageFuture(String questionId, String imageUrl) {
    return _imageFutures.putIfAbsent(questionId, () async {
      await ImageCacheService.instance.cacheImage(imageUrl);
      return ImageCacheService.instance.getImagePath(imageUrl);
    });
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 32.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 4.h),
            Text(
              'Image not available',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(question_model.Question question) {
    final options = question.options; // Use original options order
    final showFeedback = _showAnswerFeedback[question.id] ?? false;
    final userAnswer = _userAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        ...options.asMap().entries.map((entry) {
          final option = entry.value;
          final isSelected =
              userAnswer == option; // Compare with full option text
          final isCorrect = option == question.correctAnswer;
          final isUserAnswer = isSelected;

          // Determine colors based on feedback
          Color? backgroundColor;
          Color? borderColor;
          Color? circleColor;
          Color? textColor;
          IconData? icon;
          Color? iconColor;

          if (showFeedback) {
            if (isCorrect) {
              // Correct answer - always green
              backgroundColor = AppColors.success.withValues(alpha: 0.1);
              borderColor = AppColors.success;
              circleColor = AppColors.success;
              textColor = AppColors.success;
              icon = Icons.check_circle;
              iconColor = AppColors.success;
            } else if (isUserAnswer && !isCorrect) {
              // User's wrong answer - red
              backgroundColor = AppColors.error.withValues(alpha: 0.1);
              borderColor = AppColors.error;
              circleColor = AppColors.error;
              textColor = AppColors.error;
              icon = Icons.cancel;
              iconColor = AppColors.error;
            } else {
              // Other options - neutral
              backgroundColor = AppColors.grey100;
              borderColor = AppColors.grey300;
              circleColor = AppColors.grey400;
              textColor = AppColors.grey600;
            }
          } else {
            // No feedback yet - normal selection state
            if (isSelected) {
              backgroundColor = AppColors.primary.withValues(alpha: 0.1);
              borderColor = AppColors.primary;
              circleColor = AppColors.primary;
              textColor = AppColors.primary;
              icon = Icons.check_circle;
              iconColor = AppColors.primary;
            } else {
              backgroundColor = AppColors.white;
              borderColor = AppColors.grey300;
              circleColor = AppColors.grey200;
              textColor = AppColors.grey700;
            }
          }

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor, width: 0),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Clickable square for answer selection
                  GestureDetector(
                    onTap: showFeedback
                        ? null
                        : () => _selectAnswer(question.id, option),
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: isSelected ? circleColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          4.r,
                        ), // Square with rounded corners
                        border: Border.all(
                          color: isSelected ? borderColor : AppColors.grey400,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: showFeedback && isCorrect
                            ? Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 14.sp,
                              )
                            : showFeedback && isUserAnswer && !isCorrect
                            ? Icon(
                                Icons.close,
                                color: AppColors.white,
                                size: 14.sp,
                              )
                            : isSelected
                            ? Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 14.sp,
                              )
                            : null, // Empty square when not selected
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: iconColor, size: 20.sp),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context);
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final answeredCount = _userAnswers.length;
    final totalQuestions = _questions.length;
    final canGoPrevious = _currentQuestionIndex > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16.w,
          16.h,
          16.w,
          MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.answered}: $answeredCount/$totalQuestions',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  '${l10n.time}: ${_formatTime(_timeRemaining)}',
                  style: AppTextStyles.caption.copyWith(
                    color: _getTimerColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            // Navigation buttons
            Row(
              children: [
                // Previous
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: canGoPrevious ? _previousQuestion : null,
                      icon: Icon(Icons.arrow_back_ios, size: 16.sp),
                      label: Text(l10n.previous),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Next / Submit (DIRECT)
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: isLastQuestion ? _submitExam : _nextQuestion,
                      icon: Icon(
                        isLastQuestion
                            ? Icons.check_circle
                            : Icons.arrow_forward_ios,
                        size: 18.sp,
                      ),
                      label: Text(isLastQuestion ? l10n.submitExam : l10n.next),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLastQuestion
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishExamFAB() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 78.h),
      child: FloatingActionButton.extended(
        onPressed: _submitExam, // ✅ DIRECT SUBMIT
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        elevation: 8,
        icon: Icon(Icons.check_circle, size: 16.sp),
        label: Text(
          l10n.submitExam,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Save exam progress to SharedPreferences
  Future<void> _saveExamProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'currentQuestionIndex': _currentQuestionIndex,
        'userAnswers': _userAnswers,
        'timeRemaining': _timeRemaining,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_progressKey, json.encode(progressData));
      debugPrint(
        '💾 Saved exam progress: Question ${_currentQuestionIndex + 1}/${_questions.length}',
      );
    } catch (e) {
      debugPrint('❌ Error saving exam progress: $e');
    }
  }

  /// Load exam progress from SharedPreferences
  Future<void> _loadExamProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        final progressData = json.decode(progressJson) as Map<String, dynamic>;
        final savedIndex = progressData['currentQuestionIndex'] as int?;
        final savedAnswers =
            progressData['userAnswers'] as Map<String, dynamic>?;
        final savedTimeRemaining = progressData['timeRemaining'] as int?;
        final savedTimestamp = progressData['timestamp'] as String?;

        // Check if progress is recent (within 24 hours)
        if (savedTimestamp != null) {
          final savedDate = DateTime.parse(savedTimestamp);
          final now = DateTime.now();
          final difference = now.difference(savedDate);

          if (difference.inHours > 24) {
            debugPrint(
              '⏰ Saved progress is older than 24 hours, starting fresh',
            );
            await _clearExamProgress();
            return;
          }
        }

        // Restore progress if valid
        if (savedIndex != null &&
            savedIndex >= 0 &&
            savedIndex < _questions.length &&
            savedAnswers != null) {
          setState(() {
            _currentQuestionIndex = savedIndex;
            _userAnswers.clear();
            savedAnswers.forEach((key, value) {
              _userAnswers[key] = value.toString();
            });

            // Restore time remaining if available and valid
            if (savedTimeRemaining != null && savedTimeRemaining > 0) {
              _timeRemaining = savedTimeRemaining;
            }
          });

          debugPrint(
            '✅ Loaded exam progress: Question ${_currentQuestionIndex + 1}/${_questions.length}',
          );
          debugPrint('   Answers saved: ${_userAnswers.length}');
          debugPrint('   Time remaining: ${_formatTime(_timeRemaining)}');

          // Show a message to user that progress was restored
          if (mounted) {
            AppFlashMessage.showInfo(
              context,
              'Progress Restored',
              description:
                  'Resuming from question ${_currentQuestionIndex + 1}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading exam progress: $e');
    }
  }

  /// Clear saved exam progress
  Future<void> _clearExamProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ Cleared exam progress');
    } catch (e) {
      debugPrint('❌ Error clearing exam progress: $e');
    }
  }
}

// App Lifecycle Observer for security monitoring
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final _ExamTakingScreenState _examScreen;

  _AppLifecycleObserver(this._examScreen);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _examScreen._handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _examScreen._handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _examScreen._handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between foreground and background
        break;
      case AppLifecycleState.hidden:
        _examScreen._handleAppPaused();
        break;
    }
  }
}
