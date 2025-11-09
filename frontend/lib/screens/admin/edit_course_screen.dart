import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import 'create_course_screen.dart' show CourseContentItem;

class EditCourseScreen extends ConsumerStatefulWidget {
  final Course course;

  const EditCourseScreen({super.key, required this.course});

  @override
  ConsumerState<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends ConsumerState<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _courseImageUrlController;

  late String _selectedDifficulty;
  late CourseType _selectedCourseType;
  late bool _isActive;

  List<CourseContentItem> _courseContents = [];
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController = TextEditingController(
      text: widget.course.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.course.category ?? '',
    );
    _courseImageUrlController = TextEditingController(
      text: widget.course.courseImageUrl ?? '',
    );
    _selectedDifficulty = widget.course.difficulty;
    _selectedCourseType = widget.course.courseType;
    _isActive = widget.course.isActive;

    _loadCourseContents();
  }

      Future<void> _loadCourseContents() async {
        setState(() => _isLoading = true);
        try {
          // Load course with contents
          // Note: Contents are loaded from the course model
          // For now, convert existing contents if available
          if (widget.course.contents != null &&
              widget.course.contents!.isNotEmpty) {
            _courseContents = widget.course.contents!.map((content) {
              return CourseContentItem(
                type: content.contentType,
                title: content.title,
                content: content.content,
                displayOrder: content.displayOrder,
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('Error loading course contents: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _courseImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Course'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Edit Course'),
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
                    Icon(Icons.edit, size: 48.sp, color: AppColors.white),
                    SizedBox(height: 12.h),
                    Text(
                      'Edit Course',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.white,
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.course.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
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
                controller: _courseImageUrlController,
                label: 'Course Image URL',
                hint: 'course1.png',
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
                'Add or edit content. Text is required, other types are optional.',
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

              // Update Button
              CustomButton(
                text: _isSubmitting ? 'Updating...' : 'Update Course',
                onPressed: _isSubmitting ? null : _handleUpdateCourse,
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
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
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
                        : 'URL (e.g., image.png) *',
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

  Future<void> _handleUpdateCourse() async {
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

      final request = UpdateCourseRequest(
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
        courseImageUrl: _courseImageUrlController.text.trim().isEmpty
            ? null
            : _courseImageUrlController.text.trim(),
        contents: contents,
      );

      final success = await ref
          .read(courseProvider.notifier)
          .updateCourse(widget.course.id, request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          AppFlashMessage.showSuccess(context, 'Course updated successfully');
          Navigator.pop(context);
        } else {
          AppFlashMessage.showError(context, 'Failed to update course');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppFlashMessage.showError(context, 'Error updating course: $e');
      }
    }
  }
}
