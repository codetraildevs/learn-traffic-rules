import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:learn_traffic_rules/services/flash_message_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../services/api_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/custom_button.dart';
import 'question_upload_screen.dart';

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

  void _showEditQuestionDialog(Question question) {
    showDialog(
      context: context,
      builder: (context) => _EditQuestionDialog(
        exam: widget.exam,
        question: question,
        onQuestionUpdated: _loadQuestions,
      ),
    );
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        exam: widget.exam,
        onQuestionAdded: _loadQuestions,
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
            onPressed: _showAddQuestionDialog,
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
            onPressed: _showAddQuestionDialog,
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
                    question.questionImgUrl!,
                    fit: BoxFit.cover,
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
                  onPressed: () => _showEditQuestionDialog(question),
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

class _AddQuestionDialog extends StatefulWidget {
  final Exam exam;
  final VoidCallback onQuestionAdded;

  const _AddQuestionDialog({required this.exam, required this.onQuestionAdded});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _correctAnswerController = TextEditingController();

  File? _selectedQuestionImage;
  bool _isUploading = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }

  Future<void> _addQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic> formData = {
        'question': _questionController.text.trim(),
        'option1': _optionAController.text.trim(),
        'option2': _optionBController.text.trim(),
        'option3': _optionCController.text.trim(),
        'option4': _optionDController.text.trim(),
        'correctAnswer': _correctAnswerController.text.trim(),
        'points': 1,
      };

      if (_selectedQuestionImage != null) {
        final imageUrl = await _imageUploadService.uploadQuestionImage(
          _selectedQuestionImage!,
        );
        if (imageUrl != null) {
          formData['questionImgUrl'] = imageUrl;
        }
      }

      final response = await ApiService().makeRequest(
        'POST',
        '/exams/${widget.exam.id}/upload-single-question',
        body: formData,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        AppFlashMessage.showSuccess(context, 'Question added successfully!');
        widget.onQuestionAdded();
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        AppFlashMessage.showError(
          context,
          response['message'] ?? 'Failed to add question',
        );
      }
    } catch (e) {
      AppFlashMessage.showError(context, 'Error adding question: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _questionController,
                label: 'Question *',
                hint: 'Enter the question',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _optionAController,
                label: 'Option A *',
                hint: 'First option',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionBController,
                label: 'Option B *',
                hint: 'Second option',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionCController,
                label: 'Option C',
                hint: 'Third option (optional)',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionDController,
                label: 'Option D',
                hint: 'Fourth option (optional)',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _correctAnswerController,
                label: 'Correct Answer *',
                hint: 'Enter the correct answer text',
              ),
              SizedBox(height: 16.h),
              _buildQuestionImagePicker(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _addQuestion,
          child: _isUploading
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Question'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildQuestionImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Image (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _pickQuestionImage,
          child: Container(
            width: double.infinity,
            height: 80.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedQuestionImage != null
                    ? AppColors.primary
                    : AppColors.grey300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8.r),
              color: AppColors.grey50,
            ),
            child: _selectedQuestionImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.file(
                      _selectedQuestionImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24.sp,
                        color: AppColors.grey400,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Tap to add image',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickQuestionImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedQuestionImage = File(result.files.first.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Error picking image: $e');
    }
  }
}

class _EditQuestionDialog extends StatefulWidget {
  final Exam exam;
  final Question question;
  final VoidCallback onQuestionUpdated;

  const _EditQuestionDialog({
    required this.exam,
    required this.question,
    required this.onQuestionUpdated,
  });

  @override
  State<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<_EditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  late TextEditingController _correctAnswerController;

  File? _selectedQuestionImage;
  bool _isUploading = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);
    _optionAController = TextEditingController(text: widget.question.option1);
    _optionBController = TextEditingController(text: widget.question.option2);
    _optionCController = TextEditingController(text: widget.question.option3);
    _optionDController = TextEditingController(text: widget.question.option4);
    _correctAnswerController = TextEditingController(
      text: widget.question.correctAnswer,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }

  Future<void> _updateQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic> formData = {
        'question': _questionController.text.trim(),
        'option1': _optionAController.text.trim(),
        'option2': _optionBController.text.trim(),
        'option3': _optionCController.text.trim(),
        'option4': _optionDController.text.trim(),
        'correctAnswer': _correctAnswerController.text.trim(),
        'points': widget.question.points,
      };

      if (_selectedQuestionImage != null) {
        final imageUrl = await _imageUploadService.uploadQuestionImage(
          _selectedQuestionImage!,
        );
        if (imageUrl != null) {
          formData['questionImgUrl'] = imageUrl;
        }
      }

      final response = await ApiService().makeRequest(
        'PUT',
        '/exams/${widget.exam.id}/questions/${widget.question.id}',
        body: formData,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        AppFlashMessage.showSuccess(context, 'Question updated successfully!');
        widget.onQuestionUpdated();
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        AppFlashMessage.showError(
          context,
          response['message'] ?? 'Failed to update question',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Error updating question: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _questionController,
                label: 'Question *',
                hint: 'Enter the question',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _optionAController,
                label: 'Option A *',
                hint: 'First option',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionBController,
                label: 'Option B *',
                hint: 'Second option',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionCController,
                label: 'Option C',
                hint: 'Third option (optional)',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _optionDController,
                label: 'Option D',
                hint: 'Fourth option (optional)',
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _correctAnswerController,
                label: 'Correct Answer *',
                hint: 'Enter the correct answer text',
              ),
              SizedBox(height: 16.h),
              _buildQuestionImagePicker(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _updateQuestion,
          child: _isUploading
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Question'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildQuestionImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Image (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: 8.h),

        // Current image if exists
        if (widget.question.questionImgUrl != null &&
            widget.question.questionImgUrl!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Image:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  height: 80.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      widget.question.questionImgUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey100,
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.grey400,
                            size: 24.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

        // New image picker
        GestureDetector(
          onTap: _pickQuestionImage,
          child: Container(
            width: double.infinity,
            height: 80.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedQuestionImage != null
                    ? AppColors.primary
                    : AppColors.grey300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8.r),
              color: AppColors.grey50,
            ),
            child: _selectedQuestionImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.file(
                      _selectedQuestionImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24.sp,
                        color: AppColors.grey400,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Tap to change image',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickQuestionImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedQuestionImage = File(result.files.first.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Error picking image: $e');
    }
  }
}
