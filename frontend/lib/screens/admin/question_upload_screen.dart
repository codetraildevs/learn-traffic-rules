import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../services/flash_message_service.dart';
import '../../services/api_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/custom_button.dart';

class QuestionUploadScreen extends ConsumerStatefulWidget {
  final Exam exam;

  const QuestionUploadScreen({super.key, required this.exam});

  @override
  ConsumerState<QuestionUploadScreen> createState() =>
      _QuestionUploadScreenState();
}

class _QuestionUploadScreenState extends ConsumerState<QuestionUploadScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Single question form
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  bool _isUploadingSingle = false;
  bool _isUploadingBulk = false;
  File? _selectedFile;
  File? _selectedQuestionImage;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          'Upload Questions',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam Info Card
                _buildExamInfoCard(),
                SizedBox(height: 24.h),

                // Upload Options
                _buildUploadOptions(),
                SizedBox(height: 24.h),

                // Single Question Form
                _buildSingleQuestionForm(),
                SizedBox(height: 24.h),

                // Bulk Upload Section
                _buildBulkUploadSection(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Exam Image
          if (widget.exam.examImgUrl != null &&
              widget.exam.examImgUrl!.isNotEmpty)
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: AppColors.grey100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  widget.exam.examImgUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.quiz,
                      color: AppColors.grey400,
                      size: 24.sp,
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: AppColors.grey100,
              ),
              child: Icon(Icons.quiz, color: AppColors.grey400, size: 24.sp),
            ),
          SizedBox(width: 16.w),

          // Exam Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.title,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.grey800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.exam.description ?? 'No description',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildInfoChip(Icons.timer, widget.exam.durationDisplay),
                    SizedBox(width: 8.w),
                    _buildInfoChip(
                      Icons.trending_up,
                      '${widget.exam.passingScore}% pass',
                    ),
                    SizedBox(width: 8.w),
                    _buildInfoChip(
                      Icons.device_unknown,
                      widget.exam.difficultyDisplay,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primary),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Options',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey800),
          ),
          SizedBox(height: 12.h),
          Text(
            'Choose how you want to add questions to this exam:',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Single Question',
                  subtitle: 'Add one question at a time',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.upload_file,
                  title: 'Bulk Upload',
                  subtitle: 'Upload CSV or Excel file',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
          Icon(icon, size: 32.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleQuestionForm() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Add Single Question',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Question Text
            _buildTextField(
              controller: _questionController,
              label: 'Question *',
              hint: 'Enter the question text',
              maxLines: 3,
            ),
            SizedBox(height: 16.h),

            // Options
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _optionAController,
                    label: 'Option A *',
                    hint: 'First option',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _optionBController,
                    label: 'Option B *',
                    hint: 'Second option',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _optionCController,
                    label: 'Option C *',
                    hint: 'Third option',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _optionDController,
                    label: 'Option D *',
                    hint: 'Fourth option',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Correct Answer
            _buildTextField(
              controller: _correctAnswerController,
              label: 'Correct Answer *',
              hint: 'Enter the correct answer text',
            ),
            SizedBox(height: 16.h),

            // Question Image Upload
            _buildQuestionImagePicker(),
            SizedBox(height: 24.h),

            // Submit Button
            CustomButton(
              text: _isUploadingSingle ? 'Uploading...' : 'Add Question',
              onPressed: _isUploadingSingle ? null : _uploadSingleQuestion,
              backgroundColor: AppColors.primary,
              textColor: AppColors.white,
              width: double.infinity,
              height: 48.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.secondary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Bulk Upload Questions',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Upload a CSV or Excel file with multiple questions. Each row should contain: question, option1, option2, option3, option4, correctAnswer, questionImgUrl, points',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
          SizedBox(height: 16.h),

          // File Selection
          GestureDetector(
            onTap: _selectFile,
            child: Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppColors.success
                      : AppColors.grey300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle
                        : Icons.cloud_upload,
                    color: _selectedFile != null
                        ? AppColors.success
                        : AppColors.grey400,
                    size: 32.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _selectedFile != null
                        ? 'File Selected: ${_selectedFile!.path.split('/').last}'
                        : 'Tap to select CSV or Excel file',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedFile != null
                          ? AppColors.success
                          : AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Tap to change file',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Upload Button
          CustomButton(
            text: _isUploadingBulk ? 'Uploading...' : 'Upload Questions',
            onPressed: _selectedFile != null && !_isUploadingBulk
                ? _uploadBulkQuestions
                : null,
            backgroundColor: _selectedFile != null
                ? AppColors.secondary
                : AppColors.grey400,
            textColor: AppColors.white,
            width: double.infinity,
            height: 48.h,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Failed to select file: $e');
    }
  }

  Future<void> _uploadSingleQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploadingSingle = true;
    });

    try {
      // Prepare form data for multipart upload
      Map<String, dynamic> formData = {
        'question': _questionController.text.trim(),
        'option1': _optionAController.text.trim(),
        'option2': _optionBController.text.trim(),
        'option3': _optionCController.text.trim(),
        'option4': _optionDController.text.trim(),
        'correctAnswer': _correctAnswerController.text.trim(),
        'points': 1,
      };

      // Upload question image if selected
      if (_selectedQuestionImage != null) {
        final imageUrl = await _imageUploadService.uploadQuestionImage(
          _selectedQuestionImage!,
        );
        if (imageUrl != null) {
          formData['questionImgUrl'] = imageUrl;
        }
      }

      final apiService = ApiService();
      final response = await apiService.makeRequest(
        'POST',
        '${AppConstants.examsEndpoint}/${widget.exam.id}/upload-single-question',
        body: formData,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        AppFlashMessage.showSuccess(context, 'Question added successfully!');
        _clearForm();
      } else {
        if (!mounted) return;
        AppFlashMessage.showError(
          context,
          response['message'] ?? 'Failed to add question',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Failed to add question: $e');
    } finally {
      setState(() {
        _isUploadingSingle = false;
      });
    }
  }

  Future<void> _uploadBulkQuestions() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploadingBulk = true;
    });

    try {
      final fileExtension = _selectedFile!.path.split('.').last.toLowerCase();

      if (fileExtension != 'csv') {
        throw Exception('Only CSV files are supported for bulk upload.');
      }

      // Parse CSV file and upload questions individually
      final csvContent = await _selectedFile!.readAsString();
      final lines = csvContent.split('\n');

      if (lines.length < 2) {
        throw Exception(
          'CSV file must contain at least a header row and one data row.',
        );
      }

      // Skip header row (first line)
      final dataLines = lines
          .skip(1)
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (dataLines.isEmpty) {
        throw Exception('No data rows found in CSV file.');
      }

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      if (!mounted) return;
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Uploading Questions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Processing ${dataLines.length} questions...'),
            ],
          ),
        ),
      );

      final apiService = ApiService();

      for (int i = 0; i < dataLines.length; i++) {
        try {
          final line = dataLines[i].trim();
          if (line.isEmpty) continue;

          // Parse CSV line (handle quoted fields)
          final fields = _parseCsvLine(line);

          if (fields.length < 6) {
            errors.add(
              'Row ${i + 2}: Insufficient columns (expected 6, got ${fields.length})',
            );
            errorCount++;
            continue;
          }

          // Create question data
          final questionData = {
            'question': fields[0].trim(),
            'option1': fields[1].trim(),
            'option2': fields[2].trim(),
            'option3': fields[3].trim(),
            'option4': fields[4].trim(),
            'correctAnswer': fields[5].trim(),
            'points': fields.length > 7
                ? int.tryParse(fields[7].trim()) ?? 1
                : 1,
            if (fields.length > 6 && fields[6].trim().isNotEmpty)
              'questionImgUrl': fields[6].trim(),
          };

          // Upload individual question
          final response = await apiService.makeRequest(
            'POST',
            '${AppConstants.examsEndpoint}/${widget.exam.id}/upload-single-question',
            body: questionData,
          );

          if (response['success'] == true) {
            successCount++;
          } else {
            errors.add(
              'Row ${i + 2}: ${response['message'] ?? 'Unknown error'}',
            );
            errorCount++;
          }
        } catch (e) {
          errors.add('Row ${i + 2}: $e');
          errorCount++;
        }
      }

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      // Show results
      if (successCount > 0) {
        if (!mounted) return;
        AppFlashMessage.showSuccess(
          context,
          'Successfully uploaded $successCount questions!',
        );
        setState(() {
          _selectedFile = null;
        });
      }

      if (errorCount > 0) {
        if (!mounted) return;
        AppFlashMessage.showError(
          context,
          'Failed to upload $errorCount questions. Check console for details.',
        );
        debugPrint('Upload errors: ${errors.join('\n')}');
      }
    } catch (e) {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Failed to upload questions: $e');
    } finally {
      setState(() {
        _isUploadingBulk = false;
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }

    fields.add(currentField);
    return fields;
  }

  void _clearForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswerController.clear();
    setState(() {
      _selectedQuestionImage = null;
    });
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
        Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedQuestionImage != null
                  ? AppColors.primary
                  : AppColors.grey300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12.r),
            color: AppColors.grey50,
          ),
          child: _selectedQuestionImage != null
              ? _buildSelectedQuestionImage()
              : _buildQuestionImagePlaceholder(),
        ),
      ],
    );
  }

  Widget _buildSelectedQuestionImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.file(
            _selectedQuestionImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8.h,
          right: 8.w,
          child: GestureDetector(
            onTap: _removeQuestionImage,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionImagePlaceholder() {
    return GestureDetector(
      onTap: _pickQuestionImage,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32.sp,
            color: AppColors.grey400,
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap to add question image',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
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

  void _removeQuestionImage() {
    setState(() {
      _selectedQuestionImage = null;
    });
  }
}
