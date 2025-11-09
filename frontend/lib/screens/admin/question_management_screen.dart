import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import 'package:learn_traffic_rules/services/flash_message_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import 'question_upload_screen.dart';
import 'add_question_screen.dart';
import 'edit_question_screen.dart';

class QuestionManagementScreen extends ConsumerStatefulWidget {
  final Exam exam;

  const QuestionManagementScreen({super.key, required this.exam});

  @override
  ConsumerState<QuestionManagementScreen> createState() =>
      _QuestionManagementScreenState();
}

class _QuestionManagementScreenState
    extends ConsumerState<QuestionManagementScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  // final ImageUploadService _imageUploadService = ImageUploadService(); // Removed - not used

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService().makeRequest(
        'GET',
        '/exams/${widget.exam.id}/questions',
      );

      if (response['success'] == true) {
        setState(() {
          _questions = (response['data']['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList();
        });
      } else {
        if (!mounted) return;
        AppFlashMessage.showError(
          context,
          response['message'] ?? 'Failed to load questions',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Error loading questions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService().makeRequest(
          'DELETE',
          '/exams/${widget.exam.id}/questions/${question.id}',
        );

        if (response['success'] == true) {
          if (!mounted) return;
          AppFlashMessage.showSuccess(
            context,
            'Question deleted successfully!',
          );
          _loadQuestions();
        } else {
          if (!mounted) return;
          AppFlashMessage.showError(
            context,
            response['message'] ?? 'Failed to delete question',
          );
        }
      } catch (e) {
        if (!mounted) return;
        AppFlashMessage.showError(context, 'Error deleting question: $e');
      }
    }
  }

  void _showEditQuestionScreen(Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(
          exam: widget.exam,
          question: question,
          onQuestionUpdated: _loadQuestions,
        ),
      ),
    );
  }

  void _showAddQuestionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionScreen(
          exam: widget.exam,
          onQuestionAdded: _loadQuestions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions - ${widget.exam.title}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: _showAddQuestionScreen,
            icon: const Icon(Icons.add),
            tooltip: 'Add Question',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
          ? _buildEmptyState()
          : _buildQuestionsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionUploadScreen(exam: widget.exam),
            ),
          ).then((_) => _loadQuestions());
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Upload Questions',
        child: const Icon(Icons.upload, color: AppColors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80.sp, color: AppColors.grey400),
          SizedBox(height: 16.h),
          Text(
            'No questions yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add questions to this exam to get started',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Add First Question',
            onPressed: _showAddQuestionScreen,
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
            width: 200.w,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              question.question,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),

            // Question image if exists
            if (question.questionImgUrl != null &&
                question.questionImgUrl!.isNotEmpty)
              Container(
                height: 120.h,
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    '${AppConstants.baseUrlImage}${question.questionImgUrl!}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey100,
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.grey400,
                          size: 40.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Options
            _buildOptionsList(question),

            SizedBox(height: 16.h),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditQuestionScreen(question),
                  icon: Icon(Icons.edit, size: 18.sp),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _deleteQuestion(question),
                  icon: Icon(Icons.delete, size: 18.sp),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsList(Question question) {
    final options = [
      'A) ${question.option1}',
      'B) ${question.option2}',
      if (question.option3.isNotEmpty) 'C) ${question.option3}',
      if (question.option4.isNotEmpty) 'D) ${question.option4}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        final isCorrect = option.contains(question.correctAnswer);
        return Container(
          margin: EdgeInsets.only(bottom: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.grey50,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: isCorrect ? AppColors.success : AppColors.grey300,
              width: isCorrect ? 2 : 1,
            ),
          ),
          child: Text(
            option,
            style: AppTextStyles.bodySmall.copyWith(
              color: isCorrect ? AppColors.success : AppColors.grey700,
              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}
