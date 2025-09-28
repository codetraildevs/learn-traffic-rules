import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/exam_result_model.dart';
import '../../models/exam_model.dart';
import 'exam_taking_screen.dart';
import 'available_exams_screen.dart';

class ExamProgressScreen extends StatefulWidget {
  final Exam exam;
  final ExamResultData examResult;
  final bool isFreeExam;

  const ExamProgressScreen({
    Key? key,
    required this.exam,
    required this.examResult,
    required this.isFreeExam,
  }) : super(key: key);

  @override
  State<ExamProgressScreen> createState() => _ExamProgressScreenState();
}

class _ExamProgressScreenState extends State<ExamProgressScreen> {
  bool _isRetaking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Exam Results',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
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
          _buildHeaderCard(),
          SizedBox(height: 24.h),

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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.white, size: 32.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.exam.title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            widget.exam.description ?? '',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use Wrap for smaller screens, Row for larger screens
              if (constraints.maxWidth < 300) {
                return Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildInfoChip(
                      icon: Icons.schedule,
                      label: 'Duration',
                      value: '${widget.exam.duration} min',
                    ),
                    _buildInfoChip(
                      icon: Icons.quiz,
                      label: 'Questions',
                      value: '${widget.examResult.totalQuestions}',
                    ),
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: 'Time Spent',
                      value: '${_formatTime(widget.examResult.timeSpent)}',
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.schedule,
                        label: 'Duration',
                        value: '${widget.exam.duration} min',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.quiz,
                        label: 'Questions',
                        value: '${widget.examResult.totalQuestions}',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.timer,
                        label: 'Time Spent',
                        value: '${_formatTime(widget.examResult.timeSpent)}',
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.w),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: (isPassed ? Colors.green : Colors.red).withOpacity(
                    0.3,
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
          SizedBox(height: 24.h),

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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 16.h),

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
              backgroundColor: const Color(0xFF1976D2),
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
              backgroundColor: const Color(0xFF2E7D32),
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
              foregroundColor: const Color(0xFF2E7D32),
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailedAnswers() {
    // Debug: Print the exam result data
    print('=== DEBUG: Exam Result Data ===');
    print('Total Questions: ${widget.examResult.totalQuestions}');
    print('Correct Answers: ${widget.examResult.correctAnswers}');
    print('Question Results: ${widget.examResult.questionResults}');
    print(
      'Question Results Length: ${widget.examResult.questionResults?.length ?? 0}',
    );
    print('Exam Result ID: ${widget.examResult.id}');
    print('Exam ID: ${widget.examResult.examId}');
    print('User ID: ${widget.examResult.userId}');
    print('Score: ${widget.examResult.score}');
    print('Passed: ${widget.examResult.passed}');
    print('Is Free Exam: ${widget.examResult.isFreeExam}');
    print('Submitted At: ${widget.examResult.submittedAt}');

    if (widget.examResult.questionResults != null) {
      print('Question Results Details:');
      for (int i = 0; i < widget.examResult.questionResults!.length; i++) {
        final qr = widget.examResult.questionResults![i];
        print('  Question ${i + 1}:');
        print('    ID: ${qr.questionId}');
        print('    User Answer: ${qr.userAnswer}');
        print('    Correct Answer: ${qr.correctAnswer}');
        print('    Is Correct: ${qr.isCorrect}');
        print('    Points: ${qr.points}');
      }
    } else {
      print('❌ Question Results is NULL!');
    }
    print('=== END DEBUG ===');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
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

              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
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
              ),

              // Content
              Expanded(
                child:
                    widget.examResult.questionResults == null ||
                        widget.examResult.questionResults!.isEmpty
                    ? _buildNoResultsView()
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        itemCount: widget.examResult.questionResults!.length,
                        itemBuilder: (context, index) {
                          final questionResult =
                              widget.examResult.questionResults![index];
                          return _buildQuestionResultCard(
                            questionResult,
                            index + 1,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionResultCard(
    QuestionResult questionResult,
    int questionNumber,
  ) {
    final isCorrect = questionResult.isCorrect;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
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
                '${questionResult.points} point${questionResult.points != 1 ? 's' : ''}',
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
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
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
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
                            ? Colors.green.withOpacity(0.1)
                            : isUserAnswer && !isCorrectAnswer
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isCorrectAnswer
                              ? Colors.green
                              : isUserAnswer && !isCorrectAnswer
                              ? Colors.red
                              : Colors.grey.withOpacity(0.3),
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
                  }).toList(),
                ],
              ),
            ),

          if (questionResult.options != null &&
              questionResult.options!.isNotEmpty)
            SizedBox(height: 12.h),

          // Correct answer
          // questionResult.correctAnswer != questionResult.userAnswer
          //     ? Container(
          //         padding: EdgeInsets.all(8.w),
          //         decoration: BoxDecoration(
          //           color: Colors.green.withOpacity(0.1),
          //           borderRadius: BorderRadius.circular(8.r),
          //           border: Border.all(color: Colors.green.withOpacity(0.3)),
          //         ),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Correct Answer:',
          //               style: TextStyle(
          //                 fontSize: 12.sp,
          //                 fontWeight: FontWeight.bold,
          //                 color: Colors.green[700],
          //               ),
          //             ),
          //             SizedBox(height: 4.h),
          //             Text(
          //               questionResult.correctAnswer,
          //               style: TextStyle(
          //                 fontSize: 14.sp,
          //                 color: Colors.green[800],
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ],
          //         ),
          //       )
          //     : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
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
              label: Text('Close'),
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
}
