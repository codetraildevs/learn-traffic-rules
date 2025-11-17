import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart' as question_model;
import '../../services/exam_service.dart';
import '../../services/offline_exam_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/exam_sync_service.dart';
import '../../services/network_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/exam_result_model.dart';
import '../../providers/auth_provider.dart';
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

  void _initializeSecurity() {
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));

    // Disable screenshots on Android
    if (Platform.isAndroid) {
      _disableScreenshots();
    }
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
      _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _backgroundTime++;
        if (_backgroundTime > 30) {
          // More than 30 seconds in background
          _autoSubmitExam();
        }
      });
      debugPrint('🔒 Security: App paused, starting background timer');
    }
  }

  void _showSecurityWarning() {
    if (_securityWarningShown || _isExamCompleted) return;

    _securityWarningShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: AppColors.error, size: 24.sp),
              SizedBox(width: 8.w),
              Text(dialogL10n.securityAlert),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogL10n.examPausedDueToBackgroundActivity,
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: 12.h),
              Text(
                dialogL10n.toMaintainExamIntegrity,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                dialogL10n.stayInExamAppDuringTest,
                style: AppTextStyles.bodySmall,
              ),
              Text(
                dialogL10n.doNotSwitchToOtherApps,
                style: AppTextStyles.bodySmall,
              ),
              Text(
                dialogL10n.doNotTakeScreenshots,
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  dialogL10n.repeatedViolationsMayTerminateExam,
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
              child: Text(dialogL10n.continueExam),
            ),
          ],
        );
      },
    );
  }

  void _autoSubmitExam() {
    if (_isExamCompleted) return;

    debugPrint(
      '🔒 Security: Auto-submitting exam due to extended background time',
    );
    _isExamCompleted = true;
    _backgroundTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error, size: 24.sp),
              SizedBox(width: 8.w),
              Text(dialogL10n.examTerminated),
            ],
          ),
          content: Text(
            dialogL10n.examAutoSubmittedDueToBackgroundActivity,
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitExam();
              },
              child: Text(dialogL10n.viewResults),
            ),
          ],
        );
      },
    );
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.exit_to_app, color: AppColors.warning, size: 24.sp),
              SizedBox(width: 8.w),
              Text(dialogL10n.exitExam),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogL10n.areYouSureYouWantToExitExam,
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  dialogL10n.exitingWillSubmitAnswers,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(dialogL10n.continueExam),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitExam();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text(dialogL10n.exitAndSubmit),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadQuestions() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      debugPrint('🔍 EXAM TAKING SCREEN DEBUG - Loading questions:');
      debugPrint('   Exam ID: ${widget.exam.id}');
      debugPrint('   Exam Title: ${widget.exam.title}');
      debugPrint('   Exam Type: ${widget.exam.examType}');
      debugPrint('   Is Free Exam: ${widget.exam.isFirstTwo}');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();

      // Update offline status
      setState(() {
        _isOffline = !hasInternet;
      });

      List<question_model.Question> questions = [];

      if (hasInternet) {
        // Online: Try to load from API
        try {
          debugPrint('🌐 Online: Loading questions from API...');
          debugPrint('   API endpoint: /exams/${widget.exam.id}/take-exam');

          questions = await _examService.getQuestionsByExamId(
            widget.exam.id,
            isFreeExam: widget.exam.isFirstTwo ?? false,
            examType: widget.exam.examType,
          );
          debugPrint('   Questions received: ${questions.length}');

          // Save to offline storage for future use
          if (questions.isNotEmpty) {
            await _offlineService.saveExam(widget.exam, questions);
            debugPrint('💾 Saved exam and questions offline');
          }
        } catch (e) {
          debugPrint('❌ Failed to load from API: $e');
          debugPrint('   Error details: ${e.toString()}');

          // Check if it's a 403 payment error
          final errorString = e.toString().toLowerCase();
          final isPaymentError =
              errorString.contains('403') ||
              errorString.contains('requires payment') ||
              errorString.contains('payment');

          if (isPaymentError) {
            debugPrint('🔒 Payment error detected (403)');
            debugPrint('   Checking if this is a free exam...');
            debugPrint('   Exam isFirstTwo: ${widget.exam.isFirstTwo}');
            debugPrint('   Exam Type: ${widget.exam.examType}');

            // Check if this exam is marked as free in the frontend
            final isFreeExam = widget.exam.isFirstTwo ?? false;
            final authState = ref.read(authProvider);
            final hasAccess = authState.accessPeriod?.hasAccess ?? false;

            // If exam is marked as free but backend rejects it, try offline first
            // This handles the case where backend logic doesn't match frontend
            if (isFreeExam && !hasAccess) {
              debugPrint(
                '⚠️ Backend rejected free exam, checking offline storage...',
              );
              questions = await _loadOfflineQuestions();
              debugPrint('   Offline questions found: ${questions.length}');

              // If no offline questions, this is a backend issue
              // The exam should be accessible but backend is blocking it
              if (questions.isEmpty) {
                debugPrint('❌ No offline questions available for free exam');
                debugPrint('   This indicates a backend/frontend mismatch');
                debugPrint('   Backend is not recognizing this exam as free');
                // Don't throw here, let it show the error below
              } else {
                debugPrint('✅ Using offline questions for free exam');
              }
            } else {
              // Not a free exam, show payment error
              debugPrint('❌ This exam requires payment');
              setState(() {
                _error = l10n.examRequiresPaymentUpgrade;
                _isLoading = false;
              });
              return;
            }
          } else {
            // Other error (network, server, etc.) - try offline
            debugPrint('🔄 Non-payment error, trying offline storage...');
            questions = await _loadOfflineQuestions();
            debugPrint('   Offline questions found: ${questions.length}');
          }
        }

        // If still no questions after API call and offline check
        if (questions.isEmpty) {
          // Try to download the exam if it's marked as free
          final isFreeExam = widget.exam.isFirstTwo ?? false;
          final authState = ref.read(authProvider);
          final hasAccess = authState.accessPeriod?.hasAccess ?? false;

          if (isFreeExam && !hasAccess) {
            debugPrint('🔄 Attempting to download free exam...');
            try {
              // For free exams, try to get questions using admin endpoint or different method
              // But since we don't have admin access, we'll rely on offline storage
              // The issue is that backend is blocking free exams incorrectly
              debugPrint(
                '⚠️ Cannot download free exam - backend is blocking it',
              );
              debugPrint('   This is a backend issue that needs to be fixed');
            } catch (downloadError) {
              debugPrint('❌ Failed to download exam: $downloadError');
            }
          }
        }
      } else {
        // Offline: Load from local database
        debugPrint('📱 Offline: Loading questions from local storage...');
        questions = await _loadOfflineQuestions();
        debugPrint('   Offline questions found: ${questions.length}');
      }

      if (questions.isEmpty) {
        debugPrint('❌ No questions available after all attempts');
        debugPrint('   Exam ID: ${widget.exam.id}');
        debugPrint('   Exam Type: ${widget.exam.examType}');
        debugPrint('   Has Internet: $hasInternet');
        debugPrint('   Is Free Exam: ${widget.exam.isFirstTwo}');

        // Check if this is a free exam that was blocked by backend
        final isFreeExam = widget.exam.isFirstTwo ?? false;
        final authState = ref.read(authProvider);
        final hasAccess = authState.accessPeriod?.hasAccess ?? false;

        String errorMessage;
        if (hasInternet && isFreeExam && !hasAccess) {
          // Free exam blocked by backend - this is a backend issue
          errorMessage = l10n.unableToLoadFreeExamBackendIssue;
        } else if (hasInternet) {
          errorMessage = l10n.noQuestionsAvailableContactSupport;
        } else {
          errorMessage = l10n.noOfflineQuestionsConnectInternet;
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
        return;
      }

      // Keep questions and options in original order (no shuffling)
      setState(() {
        _questions = questions;
        _timeRemaining =
            widget.exam.duration * 60; // Convert minutes to seconds
        _isLoading = false;
      });

      debugPrint('✅ Successfully loaded ${questions.length} questions');
      debugPrint('   Timer set to: ${widget.exam.duration * 60} seconds');

      _startTimer();
      _progressController.forward();
      _questionController.forward();
      _timerController.forward();
    } catch (e) {
      debugPrint('❌ EXAM TAKING SCREEN ERROR: $e');
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.failedToLoadQuestions(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<List<question_model.Question>> _loadOfflineQuestions() async {
    try {
      final examData = await _offlineService.getExam(widget.exam.id);
      if (examData != null) {
        debugPrint(
          '📱 Loaded ${examData['questions'].length} questions from offline storage',
        );
        return examData['questions'] as List<question_model.Question>;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error loading offline questions: $e');
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isTimeUp = true;
    });
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timesUp),
        content: Text(l10n.examTimeEndedAutoSubmit),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: Text(l10n.submit),
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
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _questionController.reset();
      _questionController.forward();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _questionController.reset();
      _questionController.forward();
    }
  }

  Future<void> _submitExam() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _isExamCompleted = true; // Mark exam as completed for security
    });

    _timer?.cancel();
    _backgroundTimer?.cancel();

    // Re-enable screenshots after exam completion
    if (Platform.isAndroid) {
      await _enableScreenshots();
    }

    // Show loading dialog during submission
    if (mounted) {
      _showSubmissionLoadingDialog();
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

      final message = hasInternet
          ? l10n.examSubmittedSuccessfully
          : l10n.examSavedOfflineWillSync;

      AppFlashMessage.showSuccess(
        context,
        message,
        description: l10n.yourScore(score),
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

  void _showSubmissionLoadingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button from closing
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 24.h),
              Text(
                l10n.submittingExam,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.grey800,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.pleaseWaitProcessingAnswers,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.mayTakeFewSeconds,
                style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.loadingExam,
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              l10n.errorLoadingExam,
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
              text: l10n.goBack,
              onPressed: () => Navigator.pop(context),
              width: 120.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUpWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, size: 80.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.timesUp,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.error,
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.examTimeEndedAutoSubmit,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            SizedBox(height: 32.h),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return CustomButton(
                  text: l10n.submitExam,
                  onPressed: _submitExam,
                  width: 150.w,
                  backgroundColor: AppColors.error,
                );
              },
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
                      widget.exam.title,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontSize: 18.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.questionNumberOfTotal(
                            _currentQuestionIndex + 1,
                            _questions.length,
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
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
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Row(
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
                      );
                    },
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
                // Question number and points
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Container(
                //       padding: EdgeInsets.symmetric(
                //         horizontal: 12.w,
                //         vertical: 6.h,
                //       ),
                //       decoration: BoxDecoration(
                //         color: AppColors.primary.withValues(alpha: 0.1),
                //         borderRadius: BorderRadius.circular(12.r),
                //       ),
                //       child: Text(
                //         'Q$\1',
                //         style: AppTextStyles.caption.copyWith(
                //           color: AppColors.primary,
                //           fontWeight: FontWeight.bold,
                //           fontSize: 12.sp,
                //         ),
                //       ),
                //     ),
                //     Container(
                //       padding: EdgeInsets.symmetric(
                //         horizontal: 12.w,
                //         vertical: 6.h,
                //       ),
                //       decoration: BoxDecoration(
                //         color: AppColors.success.withValues(alpha: 0.1),
                //         borderRadius: BorderRadius.circular(12.r),
                //       ),
                //       child: Text(
                //         '$\1 point$\1',
                //         style: AppTextStyles.caption.copyWith(
                //           color: AppColors.success,
                //           fontWeight: FontWeight.bold,
                //           fontSize: 12.sp,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),

                // SizedBox(height: 16.h),

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

                // Question image if available
                if (question.questionImgUrl != null &&
                    question.questionImgUrl!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  FutureBuilder<String>(
                    future: ImageCacheService.instance
                        .getImagePath(question.questionImgUrl)
                        .catchError((e) {
                          // If cache fails, return empty string to show error widget
                          debugPrint('⚠️ Error getting image path: $e');
                          return '';
                        }),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        // If offline and no cached image, show error widget
                        if (_isOffline) {
                          return _buildImageErrorWidget();
                        }
                        return const SizedBox.shrink();
                      }

                      final imagePath = snapshot.data!;
                      // Check if it's a local file path (not a URL)
                      final isLocalFile =
                          !imagePath.startsWith('http') &&
                          !imagePath.startsWith('https') &&
                          imagePath.isNotEmpty;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: isLocalFile
                            ? FutureBuilder<bool>(
                                future: File(
                                  imagePath,
                                ).exists().catchError((e) => false),
                                builder: (context, fileSnapshot) {
                                  if (fileSnapshot.hasData &&
                                      fileSnapshot.data == true) {
                                    // Image is cached, load from file
                                    return Image.file(
                                      File(imagePath),
                                      width: double.infinity,
                                      height: 200.h,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint(
                                          '❌ Error loading cached image: $error',
                                        );
                                        return _buildImageErrorWidget();
                                      },
                                    );
                                  } else {
                                    // File doesn't exist
                                    // If offline, show error widget
                                    // If online, try network (might be a new image)
                                    if (_isOffline) {
                                      return _buildImageErrorWidget();
                                    }
                                    return Image.network(
                                      question.questionImgUrl!.startsWith(
                                            'http',
                                          )
                                          ? question.questionImgUrl!
                                          : '${AppConstants.baseUrlImage}${question.questionImgUrl}',
                                      width: double.infinity,
                                      height: 200.h,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildImageErrorWidget();
                                          },
                                    );
                                  }
                                },
                              )
                            : Builder(
                                // Network URL - only try if online
                                builder: (context) {
                                  if (_isOffline) {
                                    // Offline and image not cached, show error widget
                                    return _buildImageErrorWidget();
                                  }
                                  // Online, try to load from network
                                  return Image.network(
                                    imagePath,
                                    width: double.infinity,
                                    height: 200.h,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImageErrorWidget();
                                    },
                                  );
                                },
                              ),
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.imageNotAvailable,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey500,
                  ),
                );
              },
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
    final l10n = AppLocalizations.of(context)!;
    final hasAnswer = _userAnswers.containsKey(
      _questions[_currentQuestionIndex].id,
    );
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
          MediaQuery.of(context).padding.bottom + 0.h,
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.answeredCountOfTotal(answeredCount, totalQuestions),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.timeLabel(_formatTime(_timeRemaining)),
                      style: AppTextStyles.caption.copyWith(
                        color: _getTimerColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 30.h),

            // Navigation buttons
            Row(
              children: [
                // Previous button
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: canGoPrevious ? _previousQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGoPrevious
                            ? AppColors.grey100
                            : AppColors.grey200,
                        foregroundColor: canGoPrevious
                            ? AppColors.grey800
                            : AppColors.grey400,
                        elevation: canGoPrevious ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: canGoPrevious
                                ? AppColors.grey300
                                : AppColors.grey200,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 16.sp,
                        color: canGoPrevious
                            ? AppColors.grey800
                            : AppColors.grey400,
                      ),
                      label: Text(
                        l10n.previous,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: canGoPrevious
                              ? AppColors.grey800
                              : AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Next/Submit button
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: hasAnswer
                          ? (isLastQuestion
                                ? _showFinishExamDialog
                                : _nextQuestion)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasAnswer
                            ? (isLastQuestion
                                  ? AppColors.success
                                  : AppColors.primary)
                            : AppColors.grey300,
                        foregroundColor: hasAnswer
                            ? AppColors.white
                            : AppColors.grey500,
                        elevation: hasAnswer ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                      ),
                      icon: Icon(
                        isLastQuestion
                            ? Icons.check_circle
                            : Icons.arrow_forward_ios,
                        size: 18.sp,
                        color: hasAnswer ? AppColors.white : AppColors.grey500,
                      ),
                      label: Text(
                        isLastQuestion ? l10n.submitExam : l10n.next,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: hasAnswer
                              ? AppColors.white
                              : AppColors.grey500,
                        ),
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
    final answeredCount = _userAnswers.length;
    final totalQuestions = _questions.length;
    final allAnswered = answeredCount == totalQuestions;

    return Padding(
      padding: EdgeInsets.only(bottom: 78.h),
      child: FloatingActionButton.extended(
        onPressed: _showFinishExamDialog,
        backgroundColor: allAnswered ? AppColors.success : AppColors.warning,
        foregroundColor: AppColors.white,
        elevation: 8,
        label: Row(
          children: [
            Icon(allAnswered ? Icons.check_circle : Icons.warning, size: 12.sp),
            SizedBox(width: 4.w),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  allAnswered ? l10n.submitExam : l10n.finishExam,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishExamDialog() {
    final answeredCount = _userAnswers.length;
    final totalQuestions = _questions.length;
    final unansweredCount = totalQuestions - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Builder(
        builder: (dialogContext) {
          final dialogL10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  dialogL10n.finishExamQuestion,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogL10n.areYouSureYouWantToFinishExam,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey700,
                  ),
                ),
                SizedBox(height: 16.h),
                if (unansweredCount > 0) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            dialogL10n.youHaveUnansweredQuestions(
                              unansweredCount,
                              unansweredCount == 1 ? '' : 's',
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                Text(
                  dialogL10n.onceSubmittedCannotChange,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  dialogL10n.continueExam,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitExam();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  dialogL10n.finishExam,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
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
