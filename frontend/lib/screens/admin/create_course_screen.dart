import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/flash_message_service.dart';
import '../../services/course_file_upload_service.dart';
import '../../widgets/custom_button.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  String _selectedDifficulty = 'MEDIUM';
  CourseType _selectedCourseType = CourseType.free;
  bool _isActive = true;
  String? _courseImageUrl;
  File? _selectedImageFile;
  bool _isUploadingImage = false;
  final TextEditingController _courseImageUrlController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _courseImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCourseImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        setState(() {
          _selectedImageFile = File(result.files.single.path!);
        });
        await _uploadCourseImage();
      }
    } catch (e) {
      if (mounted) {
        AppFlashMessage.showError(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _uploadCourseImage() async {
    if (_selectedImageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final uploadService = CourseFileUploadService();
      final fileUrl = await uploadService.uploadCourseImage(
        _selectedImageFile!,
      );

      if (fileUrl != null) {
        // Extract relative path from full URL if needed
        if (fileUrl.startsWith(AppConstants.baseUrlImage)) {
          setState(() {
            _courseImageUrl = fileUrl.replaceFirst(
              AppConstants.baseUrlImage,
              '',
            );
            _courseImageUrlController.text = _courseImageUrl!;
          });
        } else {
          setState(() {
            _courseImageUrl = fileUrl;
            _courseImageUrlController.text = _courseImageUrl!;
          });
        }
      } else {
        if (mounted) {
          AppFlashMessage.showError(context, 'Failed to upload image');
        }
      }
    } catch (e) {
      if (mounted) {
        AppFlashMessage.showError(context, 'Error uploading image: $e');
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Create New Course'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 48.sp, color: AppColors.white),
                    SizedBox(height: 12.h),
                    Text(
                      'Create New Course',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.white,
                        fontSize: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              SizedBox(height: 16.h),

              _buildTextField(
                controller: _titleController,
                label: 'Course Title',
                hint: 'e.g., Basic Traffic Rules',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter course description',
                maxLines: 3,
              ),

              SizedBox(height: 16.h),

              _buildTextField(
                controller: _categoryController,
                label: 'Category',
                hint: 'e.g., Beginner, Intermediate, Advanced',
              ),

              SizedBox(height: 16.h),

              // Course Image (Optional)
              _buildSectionTitle('Course Image (Optional)'),
              SizedBox(height: 12.h),
              _buildCourseImageField(),

              SizedBox(height: 24.h),

              // Course Settings
              _buildSectionTitle('Course Settings'),
              SizedBox(height: 16.h),

              // Difficulty
              _buildDropdownField(
                label: 'Difficulty',
                value: _selectedDifficulty,
                items: const ['EASY', 'MEDIUM', 'HARD'],
                onChanged: (value) {
                  setState(() => _selectedDifficulty = value!);
                },
              ),

              SizedBox(height: 16.h),

              // Course Type (Free/Paid)
              _buildSectionTitle('Course Type'),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildCourseTypeOption(
                      CourseType.free,
                      'Free',
                      Icons.free_breakfast,
                      AppColors.success,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildCourseTypeOption(
                      CourseType.paid,
                      'Paid',
                      Icons.payment,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Active Status
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Course will be visible to users'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                activeThumbColor: AppColors.primary,
              ),

              SizedBox(height: 32.h),

              // Submit Button
              CustomButton(
                text: _isSubmitting ? 'Creating...' : 'Create Course',
                onPressed: _isSubmitting ? null : _handleCreateCourse,
                backgroundColor: AppColors.primary,
                textColor: AppColors.white,
                width: double.infinity,
              ),

              SizedBox(height: 24.h),
            ],
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
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }

  Widget _buildCourseImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              if (_selectedImageFile != null) ...[
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 12.h),
              ] else if (_courseImageUrl != null &&
                  _courseImageUrl!.isNotEmpty) ...[
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      '${AppConstants.baseUrlImage}$_courseImageUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48.sp,
                            color: AppColors.grey400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _isUploadingImage
                          ? 'Uploading...'
                          : _selectedImageFile != null
                          ? 'Change Image'
                          : 'Pick Image',
                      onPressed: _isUploadingImage ? null : _pickCourseImage,
                      backgroundColor: AppColors.secondary,
                      textColor: AppColors.white,
                      icon: Icons.image,
                    ),
                  ),
                  if ((_selectedImageFile != null || _courseImageUrl != null) &&
                      !_isUploadingImage) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        text: 'Remove',
                        onPressed: () {
                          setState(() {
                            _selectedImageFile = null;
                            _courseImageUrl = null;
                            _courseImageUrlController.clear();
                          });
                        },
                        backgroundColor: AppColors.grey400,
                        textColor: AppColors.white,
                        icon: Icons.delete,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _courseImageUrlController,
                decoration: InputDecoration(
                  labelText: 'Or enter image URL/path',
                  hintText: '/uploads/courses/images/course1.png',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                ),
                onChanged: (value) {
                  _courseImageUrl = value.isEmpty ? null : value;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: AppColors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCourseTypeOption(
    CourseType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCourseType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCourseType = type);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? color : AppColors.grey600,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateCourseRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        difficulty: _selectedDifficulty,
        courseType: _selectedCourseType,
        isActive: _isActive,
        courseImageUrl: _courseImageUrl?.isEmpty == true
            ? null
            : _courseImageUrl,
        contents:
            [], // Content is managed separately via CourseDetailManagementScreen
      );

      final success = await ref
          .read(courseProvider.notifier)
          .createCourse(request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          AppFlashMessage.showSuccess(context, 'Course created successfully');
          Navigator.pop(context);
        } else {
          AppFlashMessage.showError(context, 'Failed to create course');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppFlashMessage.showError(context, 'Error creating course: $e');
      }
    }
  }
}
