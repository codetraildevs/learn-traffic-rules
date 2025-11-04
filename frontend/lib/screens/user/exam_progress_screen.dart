import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import 'exam_taking_screen.dart';
import 'available_exams_screen.dart';

class ExamProgressScreen extends StatefulWidget {
  final Exam exam;
  final ExamResultData examResult;
  final bool isFreeExam;

  const ExamProgressScreen({
    super.key,
    required this.exam,
    required this.examResult,
    required this.isFreeExam,
  });

  @override
  State<ExamProgressScreen> createState() => _ExamProgressScreenState();
}

class _ExamProgressScreenState extends State<ExamProgressScreen> {
  bool _isRetaking = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Result of ${widget.exam.title}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isRetaking ? _buildRetakingView() : _buildResultsView(),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          // _buildHeaderCard(),
          // SizedBox(height: 24.h),

          // Score Overview
          _buildScoreOverview(),
          SizedBox(height: 24.h),

          // Detailed Results
          _buildDetailedResults(),
          SizedBox(height: 24.h),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildScoreOverview() {
    final score = widget.examResult.score;
    final isPassed = widget.examResult.passed;
    final passingScore = widget.exam.passingScore;

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
        children: [
          // Score Circle
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPassed
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : [const Color(0xFFFF5722), const Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPassed ? Colors.green : Colors.red).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isPassed ? 'PASSED' : 'FAILED',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Score Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreDetail(
                label: 'Correct',
                value: '${widget.examResult.correctAnswers}',
                color: const Color(0xFF4CAF50),
              ),
              _buildScoreDetail(
                label: 'Incorrect',
                value:
                    '${widget.examResult.totalQuestions - widget.examResult.correctAnswers}',
                color: const Color(0xFFFF5722),
              ),
              _buildScoreDetail(
                label: 'Passing Score',
                value: '$passingScore%',
                color: const Color(0xFF2196F3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetail({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
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
        ),
      ],
    );
  }

  Widget _buildDetailedResults() {
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
            'Exam Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),

          _buildResultRow(
            icon: Icons.quiz,
            label: 'Total Questions',
            value: '${widget.examResult.totalQuestions}',
          ),
          _buildResultRow(
            icon: Icons.check_circle,
            label: 'Correct Answers',
            value: '${widget.examResult.correctAnswers}',
            color: const Color(0xFF4CAF50),
          ),
          _buildResultRow(
            icon: Icons.cancel,
            label: 'Incorrect Answers',
            value:
                '${widget.examResult.totalQuestions - widget.examResult.correctAnswers}',
            color: const Color(0xFFFF5722),
          ),
          _buildResultRow(
            icon: Icons.timer,
            label: 'Time Spent',
            value: _formatTime(widget.examResult.timeSpent),
          ),
          _buildResultRow(
            icon: Icons.schedule,
            label: 'Completed At',
            value: _formatDateTime(widget.examResult.submittedAt),
          ),
          if (widget.isFreeExam)
            _buildResultRow(
              icon: Icons.free_breakfast,
              label: 'Exam Type',
              value: 'Free Exam',
              color: const Color(0xFF2196F3),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[600], size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: color ?? Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Check Answers Button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton.icon(
            onPressed: _showDetailedAnswers,
            icon: Icon(Icons.quiz, size: 20.w),
            label: Text(
              'Check Answers',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Retake Button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton.icon(
            onPressed: _retakeExam,
            icon: Icon(Icons.refresh, size: 20.w),
            label: Text(
              'Retake Exam',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Back to Exams Button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton.icon(
            onPressed: _backToExams,
            icon: Icon(Icons.list, size: 20.w),
            label: Text(
              'Back to Exams',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetakingView() {
    return ExamTakingScreen(
      exam: widget.exam,
      isFreeExam: widget.isFreeExam,
      onExamCompleted: (result) {
        setState(() {
          _isRetaking = false;
        });
        // Navigate to new results
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamProgressScreen(
              exam: widget.exam,
              examResult: result,
              isFreeExam: widget.isFreeExam,
            ),
          ),
        );
      },
    );
  }

  void _retakeExam() {
    setState(() {
      _isRetaking = true;
    });
  }

  void _backToExams() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AvailableExamsScreen()),
      (route) => false,
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

  void _showDetailedAnswers() async {
    // Disable screenshots before showing detailed answers
    await _disableScreenshots();

    // Debug: Print the exam result data
    debugPrint('=== DEBUG: Exam Result Data ===');
    debugPrint('Total Questions: ${widget.examResult.totalQuestions}');
    debugPrint('Correct Answers: ${widget.examResult.correctAnswers}');
    debugPrint(
      'Incorrect Answers: ${widget.examResult.totalQuestions - widget.examResult.correctAnswers}',
    );
    debugPrint('Score: ${widget.examResult.score}%');
    debugPrint('Passed: ${widget.examResult.passed}');
    debugPrint(
      'Question Results Length: ${widget.examResult.questionResults?.length ?? 0}',
    );
    debugPrint('Exam Result ID: ${widget.examResult.id}');
    debugPrint('Exam ID: ${widget.examResult.examId}');
    debugPrint('User ID: ${widget.examResult.userId}');
    debugPrint('Score: ${widget.examResult.score}');
    debugPrint('Passed: ${widget.examResult.passed}');
    debugPrint('Is Free Exam: ${widget.examResult.isFreeExam}');
    debugPrint('Submitted At: ${widget.examResult.submittedAt}');

    if (widget.examResult.questionResults != null) {
      debugPrint('Question Results Details:');
      for (int i = 0; i < widget.examResult.questionResults!.length; i++) {
        debugPrint(
          '  Question ${widget.examResult.questionResults![i].questionId}:',
        );
        debugPrint(
          '    ID: ${widget.examResult.questionResults![i].questionId}',
        );
        debugPrint(
          '    User Answer: ${widget.examResult.questionResults![i].userAnswer}',
        );
        debugPrint(
          '    Correct Answer: ${widget.examResult.questionResults![i].correctAnswer}',
        );
        debugPrint(
          '    Is Correct: ${widget.examResult.questionResults![i].isCorrect}',
        );
        debugPrint(
          '    Points: ${widget.examResult.questionResults![i].points}',
        );
      }
    } else {
      debugPrint('❌ Question Results is NULL!');
    }
    debugPrint('=== END DEBUG ===');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureDetailedAnswersModal(
        examResult: widget.examResult,
        onClose: () async {
          // Re-enable screenshots when closing
          await _enableScreenshots();
        },
      ),
    );
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header with security warning
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.red[600], size: 20.w),
                      SizedBox(width: 8.w),
                      Text(
                        'SECURE VIEW',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.quiz,
                        color: const Color(0xFF1976D2),
                        size: 24.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Detailed Answers',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
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
                        Icon(Icons.warning, color: Colors.red[600], size: 16.w),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Screenshots are disabled to protect answer integrity',
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No Detailed Results Available',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Question-by-question results are not available for this exam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, size: 20.w),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
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
    final isCorrect = questionResult.isCorrect;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 2,
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
                  color: isCorrect ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                isCorrect ? 'Correct' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${questionResult.points} point${questionResult.points > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
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
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    questionResult.questionText!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Options:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
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
                            ? Colors.green.withValues(alpha: 0.1)
                            : isUserAnswer && !isCorrectAnswer
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isCorrectAnswer
                              ? Colors.green
                              : isUserAnswer && !isCorrectAnswer
                              ? Colors.red
                              : Colors.grey.withValues(alpha: 0.3),
                          width:
                              isCorrectAnswer ||
                                  (isUserAnswer && !isCorrectAnswer)
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrectAnswer
                                  ? Colors.green
                                  : isUserAnswer && !isCorrectAnswer
                                  ? Colors.red
                                  : Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                optionKey.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      isCorrectAnswer ||
                                          (isUserAnswer && !isCorrectAnswer)
                                      ? Colors.white
                                      : Colors.grey[600],
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
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isCorrectAnswer
                                    ? Colors.green[800]
                                    : isUserAnswer && !isCorrectAnswer
                                    ? Colors.red[800]
                                    : Colors.grey[700],
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
                              color: Colors.green,
                              size: 16.w,
                            ),
                          if (isUserAnswer && !isCorrectAnswer)
                            Icon(Icons.cancel, color: Colors.red, size: 16.w),
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
