import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../services/flash_message_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/custom_button.dart';

class EditExamScreen extends ConsumerStatefulWidget {
  final Exam exam;

  const EditExamScreen({super.key, required this.exam});

  @override
  ConsumerState<EditExamScreen> createState() => _EditExamScreenState();
}

class _EditExamScreenState extends ConsumerState<EditExamScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _durationController;
  late TextEditingController _passingScoreController;

  late String _selectedDifficulty;
  late bool _isActive;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with exam data
    _titleController = TextEditingController(text: widget.exam.title);
    _descriptionController = TextEditingController(
      text: widget.exam.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.exam.category ?? '',
    );
    _durationController = TextEditingController(
      text: widget.exam.duration.toString(),
    );
    _passingScoreController = TextEditingController(
      text: widget.exam.passingScore.toString(),
    );

    // Initialize image URL
    _uploadedImageUrl = widget.exam.examImgUrl;

    _selectedDifficulty = widget.exam.difficulty;
    _isActive = widget.exam.isActive;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examState = ref.watch(examProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Edit Exam'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.edit, size: 48.sp, color: AppColors.white),
                        SizedBox(height: 12.h),
                        Text(
                          'Edit Exam',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.white,
                            fontSize: 24.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Update exam settings and information',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Form Fields
                  _buildSectionTitle('Basic Information'),
                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _titleController,
                    label: 'Exam Title',
                    hint: 'e.g., Basic Traffic Rules Test',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter exam title';
                      }
                      if (value.length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Describe what this exam covers...',
                    maxLines: 3,
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _categoryController,
                    label: 'Category (Optional)',
                    hint: 'e.g., Road Signs, Traffic Lights, Speed Limits',
                  ),

                  SizedBox(height: 24.h),

                  _buildSectionTitle('Exam Settings'),
                  SizedBox(height: 16.h),

                  // Difficulty Selection
                  Text(
                    'Difficulty Level',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _buildDifficultyOption('EASY', 'Easy')),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildDifficultyOption('MEDIUM', 'Medium'),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildDifficultyOption('HARD', 'Hard')),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Duration
                  _buildTextField(
                    controller: _durationController,
                    label: 'Duration (minutes)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final duration = int.tryParse(value);
                      if (duration == null || duration < 5 || duration > 180) {
                        return '5-180 minutes';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _passingScoreController,
                    label: 'Passing Score (%)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final score = int.tryParse(value);
                      if (score == null || score < 50 || score > 100) {
                        return '50-100%';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24.h),

                  _buildSectionTitle('Additional Settings'),
                  SizedBox(height: 16.h),

                  _buildImagePicker(),

                  SizedBox(height: 24.h),

                  // Status Toggle
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.toggle_on,
                          color: _isActive
                              ? AppColors.success
                              : AppColors.grey400,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Status',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isActive
                                    ? 'Exam will be available to students'
                                    : 'Exam will be hidden from students',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeThumbColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: AppColors.grey200,
                          textColor: AppColors.grey700,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomButton(
                          text: 'Update Exam',
                          onPressed: examState.isLoading ? null : _updateExam,
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontSize: 18.sp,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(String value, String label) {
    final isSelected = _selectedDifficulty == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.grey700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _updateExam() async {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdateExamRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      difficulty: _selectedDifficulty,
      duration: int.parse(_durationController.text),
      passingScore: int.parse(_passingScoreController.text),
      isActive: _isActive,
      examImgUrl: _uploadedImageUrl,
    );

    final success = await ref
        .read(examProvider.notifier)
        .updateExam(widget.exam.id, request);

    if (success) {
      if (!mounted) return;
      AppFlashMessage.showSuccess(context, 'Exam updated successfully!');
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      AppFlashMessage.showError(
        context,
        'Failed to update exam. Please try again.',
      );
    }
  }

  /// Build image picker section
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exam Image (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        SizedBox(height: 8.h),

        // Current image or placeholder
        if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
          _buildCurrentImage()
        else
          _buildImagePlaceholder(),

        SizedBox(height: 12.h),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: _selectedImage != null ? 'Change Image' : 'Select Image',
                onPressed: _pickImage,
                backgroundColor: AppColors.primary,
                textColor: AppColors.white,
                height: 40.h,
                fontSize: 14.sp,
              ),
            ),
            if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  text: 'Remove',
                  onPressed: _removeImage,
                  backgroundColor: AppColors.error,
                  textColor: AppColors.white,
                  height: 40.h,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),

        if (_isUploadingImage) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Uploading image...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build current image display
  Widget _buildCurrentImage() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          _uploadedImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.grey200,
              child: Icon(
                Icons.image_not_supported,
                color: AppColors.grey400,
                size: 40.sp,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.grey200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build image placeholder
  Widget _buildImagePlaceholder() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey300, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40.sp, color: AppColors.grey400),
          SizedBox(height: 8.h),
          Text(
            'No image selected',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = File(result.files.first.path!);
        });
        await _uploadImage(_selectedImage!);
      }
    } catch (e) {
      if (mounted) {
        AppFlashMessage.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  /// Upload image to server
  Future<void> _uploadImage(File image) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUploadService = ImageUploadService();
      final imageUrl = await imageUploadService.uploadImage(image);

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        AppFlashMessage.showSuccess(context, 'Image uploaded successfully!');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        AppFlashMessage.showError(context, 'Failed to upload image: $e');
      }
    }
  }

  /// Remove current image
  void _removeImage() {
    setState(() {
      _uploadedImageUrl = null;
      _selectedImage = null;
    });
  }
}
