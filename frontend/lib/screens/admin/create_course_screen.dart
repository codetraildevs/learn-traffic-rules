import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/flash_message_service.dart';
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

  List<CourseContentItem> _courseContents = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
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

              // Course Image URL
              _buildTextField(
                controller: TextEditingController(text: _courseImageUrl),
                label: 'Course Image URL',
                hint: '/uploads/course-images/course1.png',
                onChanged: (value) => _courseImageUrl = value,
                prefixText: AppConstants.baseUrlImage,
              ),

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
                activeColor: AppColors.primary,
              ),

              SizedBox(height: 24.h),

              // Course Content
              _buildSectionTitle('Course Content'),
              SizedBox(height: 12.h),
              Text(
                'Add content to your course. Text is required, other types are optional.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),

              // Content List
              ..._courseContents.asMap().entries.map((entry) {
                final index = entry.key;
                final content = entry.value;
                return _buildContentItemCard(content, index);
              }),

              SizedBox(height: 16.h),

              // Add Content Button
              CustomButton(
                text: 'Add Content',
                onPressed: _showAddContentDialog,
                backgroundColor: AppColors.primary,
                textColor: AppColors.white,
                width: double.infinity,
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
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

  Widget _buildContentItemCard(CourseContentItem content, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Icon(
          _getContentTypeIcon(content.type),
          color: _getContentTypeColor(content.type),
        ),
        title: Text(
          content.title ?? content.type.displayName,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getContentPreview(content),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editContentItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _removeContentItem(index),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getContentTypeIcon(CourseContentType type) {
    switch (type) {
      case CourseContentType.text:
        return Icons.article;
      case CourseContentType.image:
        return Icons.image;
      case CourseContentType.audio:
        return Icons.audiotrack;
      case CourseContentType.video:
        return Icons.video_library;
      case CourseContentType.link:
        return Icons.link;
    }
  }

  Color _getContentTypeColor(CourseContentType type) {
    switch (type) {
      case CourseContentType.text:
        return AppColors.primary;
      case CourseContentType.image:
        return AppColors.secondary;
      case CourseContentType.audio:
        return AppColors.warning;
      case CourseContentType.video:
        return AppColors.error;
      case CourseContentType.link:
        return AppColors.info;
    }
  }

  String _getContentPreview(CourseContentItem content) {
    if (content.type == CourseContentType.text) {
      return content.content.length > 50
          ? '${content.content.substring(0, 50)}...'
          : content.content;
    }
    return content.content;
  }

  void _showAddContentDialog() {
    _showContentDialog();
  }

  void _editContentItem(int index) {
    _showContentDialog(editIndex: index);
  }

  void _showContentDialog({int? editIndex}) {
    final isEditing = editIndex != null;
    final content = isEditing ? _courseContents[editIndex] : null;

    final titleController = TextEditingController(text: content?.title ?? '');
    final contentController = TextEditingController(
      text: content?.content ?? '',
    );
    CourseContentType selectedType = content?.type ?? CourseContentType.text;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Content' : 'Add Content'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content Type
                DropdownButtonFormField<CourseContentType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Content Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: CourseContentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                SizedBox(height: 16.h),

                // Title (Optional)
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Content
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: selectedType == CourseContentType.text
                        ? 'Text Content *'
                        : selectedType == CourseContentType.link
                        ? 'URL *'
                        : 'URL (e.g., /uploads/course-images/image.png) *',
                    hintText: _getContentHint(selectedType),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  maxLines: selectedType == CourseContentType.text ? 5 : 2,
                ),
                if (selectedType != CourseContentType.text &&
                    selectedType != CourseContentType.link)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Prefix: ${AppConstants.baseUrlImage}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content is required')),
                  );
                  return;
                }

                final contentItem = CourseContentItem(
                  type: selectedType,
                  title: titleController.text.isEmpty
                      ? null
                      : titleController.text,
                  content: contentController.text,
                  displayOrder: isEditing
                      ? content!.displayOrder
                      : _courseContents.length,
                );

                if (isEditing) {
                  setState(() {
                    _courseContents[editIndex] = contentItem;
                  });
                } else {
                  setState(() {
                    _courseContents.add(contentItem);
                  });
                }

                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentHint(CourseContentType type) {
    switch (type) {
      case CourseContentType.text:
        return 'Enter text content';
      case CourseContentType.image:
        return 'image.png';
      case CourseContentType.audio:
        return 'audio.mp3';
      case CourseContentType.video:
        return 'video.mp4';
      case CourseContentType.link:
        return 'https://example.com';
    }
  }

  void _removeContentItem(int index) {
    setState(() {
      _courseContents.removeAt(index);
      // Reorder remaining items
      for (int i = 0; i < _courseContents.length; i++) {
        _courseContents[i] = CourseContentItem(
          type: _courseContents[i].type,
          title: _courseContents[i].title,
          content: _courseContents[i].content,
          displayOrder: i,
        );
      }
    });
  }

  Future<void> _handleCreateCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one text content exists
    final hasTextContent = _courseContents.any(
      (content) => content.type == CourseContentType.text,
    );
    if (!hasTextContent) {
      AppFlashMessage.showError(
        context,
        'Course must have at least one text content item',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final contents = _courseContents.map((item) {
        return CreateCourseContentRequest(
          contentType: item.type,
          content: item.content,
          title: item.title,
          displayOrder: item.displayOrder,
        );
      }).toList();

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
        contents: contents,
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

// Helper class for managing content items in the form
class CourseContentItem {
  final CourseContentType type;
  final String? title;
  final String content;
  final int displayOrder;

  CourseContentItem({
    required this.type,
    this.title,
    required this.content,
    required this.displayOrder,
  });
}
