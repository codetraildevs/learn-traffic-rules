import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart' as question_model;
import '../../services/exam_service.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/exam_result_model.dart';
import 'exam_progress_screen.dart';

class ExamTakingScreen extends StatefulWidget {
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
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen>
    with TickerProviderStateMixin {
  final ExamService _examService = ExamService();

  // State variables
  List<question_model.Question> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  Map<String, bool> _showAnswerFeedback =
      {}; // Track if answer feedback should be shown
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Security variables
  bool _isAppInBackground = false;
  int _backgroundTime = 0;
  Timer? _backgroundTimer;
  bool _securityWarningShown = false;
  // Removed _screenshotAttempts - not needed for current implementation
  bool _isExamCompleted = false;
  static const MethodChannel _securityChannel = MethodChannel(
    'com.example.learn_traffic_rules/security',
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
      print('🔒 Security: Screenshots disabled for exam taking');
    } catch (e) {
      print('🔒 Security: Failed to disable screenshots: $e');
    }
  }

  Future<void> _enableScreenshots() async {
    try {
      await _securityChannel.invokeMethod('enableScreenshots');
      print('🔒 Security: Screenshots enabled after exam');
    } catch (e) {
      print('🔒 Security: Failed to enable screenshots: $e');
    }
  }

  void _handleAppResumed() {
    if (_isAppInBackground && !_isExamCompleted) {
      _backgroundTime++;
      print(
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
      print('🔒 Security: App paused, starting background timer');
    }
  }

  void _showSecurityWarning() {
    if (_securityWarningShown || _isExamCompleted) return;

    _securityWarningShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Security Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The exam was paused due to app switching or background activity.',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 12.h),
            Text(
              'To maintain exam integrity:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '• Stay in the exam app during the test',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              '• Do not switch to other apps',
              style: AppTextStyles.bodySmall,
            ),
            Text('• Do not take screenshots', style: AppTextStyles.bodySmall),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Repeated violations may result in exam termination.',
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
            child: const Text('Continue Exam'),
          ),
        ],
      ),
    );
  }

  void _autoSubmitExam() {
    if (_isExamCompleted) return;

    print('🔒 Security: Auto-submitting exam due to extended background time');
    _isExamCompleted = true;
    _backgroundTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Exam Terminated'),
          ],
        ),
        content: Text(
          'Your exam has been automatically submitted due to extended background activity. This is to maintain exam integrity.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.warning, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Exit Exam?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to exit the exam?',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '⚠️ Exiting will submit your current answers and end the exam.',
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
            child: const Text('Continue Exam'),
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
            child: const Text('Exit & Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    try {
      print('🔍 EXAM TAKING SCREEN DEBUG - Loading questions:');
      print('   Exam ID: ${widget.exam.id}');
      print('   Exam Title: ${widget.exam.title}');
      print('   Is Free Exam: ${widget.isFreeExam}');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('   Calling _examService.getQuestionsByExamId...');
      final questions = await _examService.getQuestionsByExamId(widget.exam.id);
      print('   Questions received: ${questions.length}');

      if (questions.isEmpty) {
        print('❌ No questions received');
        setState(() {
          _error = 'No questions available for this exam';
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

      print('✅ Successfully loaded questions');
      print('   Timer set to: ${_timeRemaining} seconds');

      _startTimer();
      _progressController.forward();
      _questionController.forward();
      _timerController.forward();
    } catch (e) {
      print('❌ EXAM TAKING SCREEN ERROR: $e');
      setState(() {
        _error = 'Failed to load questions: $e';
        _isLoading = false;
      });
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
    setState(() {
      _isTimeUp = true;
    });
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text(
          'The exam time has ended. Your answers will be submitted automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: const Text('Submit'),
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

  Color _getTimerColor() {
    final percentage = _timeRemaining / (widget.exam.duration * 60);
    if (percentage > 0.5) return AppColors.success;
    if (percentage > 0.25) return AppColors.warning;
    return AppColors.error;
  }

  void _selectAnswer(String questionId, String answer) {
    print('🔍 FRONTEND DEBUG - Answer selected:');
    print('   Question ID: $questionId');
    print('   Selected Answer: $answer');
    print('   Current answers: $_userAnswers');

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

    try {
      final result = await _examService.submitExamResult(
        examId: widget.exam.id,
        answers: _userAnswers,
        timeSpent: (widget.exam.duration * 60) - _timeRemaining,
        isFreeExam: widget.isFreeExam,
      );

      if (result.success && result.data != null) {
        AppFlashMessage.showSuccess(
          context,
          'Exam Submitted Successfully!',
          description: 'Your score: ${result.data!.score}%',
        );

        // Use callback if provided, otherwise navigate to progress screen
        if (widget.onExamCompleted != null) {
          widget.onExamCompleted!(result.data!);
        } else {
          // Navigate to progress screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExamProgressScreen(
                exam: widget.exam,
                examResult: result.data!,
                isFreeExam: widget.isFreeExam,
              ),
            ),
          );
        }
      } else {
        AppFlashMessage.showError(
          context,
          'Failed to submit exam',
          description: result.message,
        );
      }
    } catch (e) {
      AppFlashMessage.showError(
        context,
        'Error submitting exam',
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during exam
        if (!_isExamCompleted) {
          _showExitWarning();
          return false;
        }
        return true;
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading Exam...',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              'Error Loading Exam',
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
              text: 'Go Back',
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
            Text(
              'Time\'s Up!',
              style: AppTextStyles.heading2.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 16.h),
            Text(
              'Your exam time has ended. Your answers will be submitted automatically.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'Submit Exam',
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

        // Question content
        Expanded(
          child: SlideTransition(
            position: _questionAnimation,
            child: _buildQuestionContent(currentQuestion),
          ),
        ),

        // Navigation buttons
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
            color: AppColors.black.withOpacity(0.1),
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
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
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
                      color: _getTimerColor().withOpacity(0.1),
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
                        'Progress',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey600,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
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
    print("question.questionImgUrl: ${question.questionImgUrl.toString()}");
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
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
                //         color: AppColors.primary.withOpacity(0.1),
                //         borderRadius: BorderRadius.circular(12.r),
                //       ),
                //       child: Text(
                //         'Q${_currentQuestionIndex + 1}',
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
                //         color: AppColors.success.withOpacity(0.1),
                //         borderRadius: BorderRadius.circular(12.r),
                //       ),
                //       child: Text(
                //         '${question.points} point${question.points != 1 ? 's' : ''}',
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
                            color: AppColors.primary.withOpacity(0.08),
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

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      "${AppConstants.baseUrlImage}${question.questionImgUrl!}",
                      width: double.infinity,
                      height: 100.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100.h,
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
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

  Widget _buildAnswerOptions(question_model.Question question) {
    final options = question.options; // Use original options order
    final showFeedback = _showAnswerFeedback[question.id] ?? false;
    final userAnswer = _userAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final optionKey = String.fromCharCode(
            97 + index.toInt(),
          ); // a, b, c, d (lowercase)
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
              backgroundColor = AppColors.success.withOpacity(0.1);
              borderColor = AppColors.success;
              circleColor = AppColors.success;
              textColor = AppColors.success;
              icon = Icons.check_circle;
              iconColor = AppColors.success;
            } else if (isUserAnswer && !isCorrect) {
              // User's wrong answer - red
              backgroundColor = AppColors.error.withOpacity(0.1);
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
              backgroundColor = AppColors.primary.withOpacity(0.1);
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
    final hasAnswer = _userAnswers.containsKey(
      _questions[_currentQuestionIndex].id,
    );
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final answeredCount = _userAnswers.length;
    final totalQuestions = _questions.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
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
                'Answered: $answeredCount/$totalQuestions',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey600,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Time: ${_formatTime(_timeRemaining)}',
                style: AppTextStyles.caption.copyWith(
                  color: _getTimerColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous button
              Expanded(
                child: CustomButton(
                  text: 'Previous',
                  fontSize: 12.sp,
                  onPressed: _currentQuestionIndex > 0
                      ? _previousQuestion
                      : null,
                  backgroundColor: AppColors.grey200,
                  textColor: AppColors.grey700,
                  width: 30,
                ),
              ),

              SizedBox(width: 48.w),

              // Next/Submit button
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: isLastQuestion ? 'Submit Exam' : 'Next',
                  fontSize: 12.sp,
                  onPressed: hasAnswer
                      ? (isLastQuestion ? _showFinishExamDialog : _nextQuestion)
                      : null,
                  backgroundColor: isLastQuestion
                      ? AppColors.success
                      : AppColors.primary,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishExamFAB() {
    final answeredCount = _userAnswers.length;
    final totalQuestions = _questions.length;
    final allAnswered = answeredCount == totalQuestions;

    return Padding(
      padding: EdgeInsets.only(bottom: 62.h),
      child: FloatingActionButton.extended(
        onPressed: _showFinishExamDialog,
        backgroundColor: allAnswered ? AppColors.success : AppColors.warning,
        foregroundColor: AppColors.white,
        elevation: 8,
        label: Row(
          children: [
            Icon(allAnswered ? Icons.check_circle : Icons.warning, size: 12.sp),
            SizedBox(width: 4.w),
            Text(
              allAnswered ? 'Submit Exam' : 'Finish Exam',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
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
      builder: (context) => AlertDialog(
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
              'Finish Exam?',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to finish the exam?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
              ),
            ),
            SizedBox(height: 16.h),
            if (unansweredCount > 0) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
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
                        'You have $unansweredCount unanswered question${unansweredCount == 1 ? '' : 's'}.',
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
              'Once submitted, you cannot change your answers.',
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
            child: const Text(
              'Continue Exam',
              style: TextStyle(
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
            child: const Text(
              'Finish Exam',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
