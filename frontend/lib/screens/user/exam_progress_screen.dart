import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/screens/home/home_screen.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/exam_title_mapper.dart';
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
  // static const MethodChannel _securityChannel = MethodChannel(
  //   'com.trafficrules.master/security',
  // );

  // Future<void> _disableScreenshots() async {
  //   if (Platform.isAndroid) {
  //     try {
  //       await _securityChannel.invokeMethod('disableScreenshots');
  //       debugPrint('🔒 Security: Screenshots disabled for detailed answers');
  //     } catch (e) {
  //       debugPrint('🔒 Security: Failed to disable screenshots: $e');
  //     }
  //   }
  // }

  // Future<void> _enableScreenshots() async {
  //   if (Platform.isAndroid) {
  //     try {
  //       await _securityChannel.invokeMethod('enableScreenshots');
  //       debugPrint('🔒 Security: Screenshots enabled after detailed answers');
  //     } catch (e) {
  //       debugPrint('🔒 Security: Failed to enable screenshots: $e');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          ExamTitleMapper.mapTitle(context, widget.exam.title),
          style: AppTextStyles.heading3.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
      ),
      body: _isRetaking ? _buildRetakingView() : _buildResultsView(),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Overview
          _buildScoreOverview(),
          SizedBox(height: 16.h),

          // Detailed Results
          _buildDetailedResults(),
          SizedBox(height: 16.h),

          // Action Buttons
          _buildActionButtons(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildScoreOverview() {
    final l10n = AppLocalizations.of(context);
    final score = widget.examResult.score;
    final isPassed = widget.examResult.passed;
    final passingScore = widget.exam.passingScore;

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
        children: [
          // Score Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isPassed ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  '$score%',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isPassed ? l10n.passed : l10n.failed,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
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
                label: l10n.correctQuestions,
                value: '${widget.examResult.correctAnswers}',
                color: AppColors.success,
              ),
              _buildScoreDetail(
                label: l10n.incorrectQuestions,
                value:
                    '${widget.examResult.totalQuestions - widget.examResult.correctAnswers}',
                color: AppColors.error,
              ),
              _buildScoreDetail(
                label: l10n.passingScore,
                value: '$passingScore%',
                color: AppColors.primary,
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
          style: AppTextStyles.heading3.copyWith(
            fontSize: 20.sp,
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
        ),
      ],
    );
  }

  Widget _buildDetailedResults() {
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
        children: [
          Text(
            l10n.examSummary,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.grey800,
            ),
          ),
          SizedBox(height: 12.h),

          _buildResultRow(
            icon: Icons.quiz,
            label: l10n.totalQuestions,
            value: '${widget.examResult.totalQuestions}',
          ),
          _buildResultRow(
            icon: Icons.check_circle,
            label: l10n.correctAnswers,
            value: '${widget.examResult.correctAnswers}',
            color: AppColors.success,
          ),
          _buildResultRow(
            icon: Icons.cancel,
            label: l10n.incorrectAnswers,
            value:
                '${widget.examResult.totalQuestions - widget.examResult.correctAnswers}',
            color: AppColors.error,
          ),
          _buildResultRow(
            icon: Icons.timer_outlined,
            label: l10n.timeSpent,
            value: _formatTime(widget.examResult.timeSpent),
          ),
          _buildResultRow(
            icon: Icons.calendar_today,
            label: l10n.completedAt,
            value: _formatDateTime(widget.examResult.submittedAt),
          ),
          if (widget.isFreeExam)
            _buildResultRow(
              icon: Icons.free_breakfast,
              label: l10n.exam,
              value: l10n.freeExam,
              color: AppColors.primary,
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
          Icon(icon, color: color ?? AppColors.grey600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14.sp,
                color: AppColors.grey700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14.sp,
              color: color ?? AppColors.grey800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Retake Button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton.icon(
            onPressed: _retakeExam,
            icon: Icon(Icons.refresh, size: 20.sp),
            label: Text(
              l10n.retakeExam,
              style: AppTextStyles.button.copyWith(fontSize: 16.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
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
            icon: Icon(Icons.list, size: 20.sp),
            label: Text(
              l10n.backToExams,
              style: AppTextStyles.button.copyWith(
                fontSize: 16.sp,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 2),
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
    // Format: "MM/DD/YYYY at HH:MM"
    // Ensure we're using the local timezone for correct display
    final localTime = dateTime.toLocal();
    return '${localTime.month}/${localTime.day}/${localTime.year} at ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
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
                      ExamTitleMapper.mapTitle(
                        context,
                        widget.examResult.exam?.title ?? l10n.exam,
                      ),
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
