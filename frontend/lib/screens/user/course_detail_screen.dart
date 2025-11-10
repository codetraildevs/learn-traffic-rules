import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'course_content_viewer_screen.dart';
import 'payment_instructions_screen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  Course? _fullCourse;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _courseService.getCourseById(
        widget.course.id,
        includeContents: true,
      );
      if (response.success && response.data != null) {
        setState(() {
          _fullCourse = response.data;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load course details';
          _fullCourse = widget.course; // Fallback to basic course info
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading course: $e';
        _fullCourse = widget.course; // Fallback to basic course info
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Global payment: if user has access, they can access all paid courses
    final hasAccess = authState.accessPeriod?.hasAccess ?? false;
    final course = _fullCourse ?? widget.course;
    // Free courses are always accessible, paid courses require global access
    final canAccess = course.isFree || hasAccess;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(course.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourseDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourseDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _fullCourse == null
            ? _buildErrorView()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Image or Placeholder
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: AppColors.grey100,
                      ),
                      child:
                          course.courseImageUrl != null &&
                              course.courseImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                course.courseImageUrl!.startsWith('http')
                                    ? course.courseImageUrl!
                                    : '${AppConstants.baseUrlImage}${course.courseImageUrl}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.grey100,
                                    child: Center(
                                      child: Icon(
                                        Icons.school_outlined,
                                        size: 64.sp,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.school_outlined,
                                size: 64.sp,
                                color: AppColors.grey400,
                              ),
                            ),
                    ),

                    SizedBox(height: 16.h),

                    // Course Info Card
                    _buildCourseInfoCard(course),

                    SizedBox(height: 16.h),

                    // Description
                    if (course.description != null)
                      _buildDescriptionCard(course.description!),

                    SizedBox(height: 16.h),

                    // Course Contents - Show if we have contents loaded
                    if (course.contents != null && course.contents!.isNotEmpty)
                      _buildContentsSection(course.contents!, canAccess),

                    SizedBox(height: 24.h),

                    // Start Course Button Logic:
                    // 1. If contentCount > 0, show button (contents will be loaded by CourseContentViewerScreen)
                    // 2. If contents are already loaded and not empty, show button
                    // 3. Otherwise show "preparing" message
                    if ((course.contentCount != null &&
                            course.contentCount! > 0) ||
                        (course.contents != null &&
                            course.contents!.isNotEmpty))
                      CustomButton(
                        text: canAccess
                            ? 'Start Course'
                            : 'Get Access to Start',
                        onPressed: canAccess
                            ? () {
                                // Navigate to content viewer - it will load contents if needed
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CourseContentViewerScreen(
                                          course: course,
                                        ),
                                  ),
                                );
                              }
                            : () {
                                // Navigate to payment instructions for global access
                                // Once user pays, they get access to ALL paid courses
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PaymentInstructionsScreen(),
                                  ),
                                );
                              },
                        backgroundColor: canAccess
                            ? AppColors.primary
                            : AppColors.warning,
                        textColor: AppColors.white,
                        width: double.infinity,
                      )
                    else if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Course content is being prepared. Please check back later.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCourseInfoCard(Course course) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Difficulty',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      course.difficultyDisplay,
                      style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: course.isFree
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: course.isFree
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                child: Text(
                  course.courseType.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: course.isFree
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 8.h,
            children: [
              _buildInfoItem(
                Icons.article,
                '${course.contentCount ?? 0} Content Items',
                AppColors.primary,
              ),
              if (course.category != null)
                _buildInfoItem(
                  Icons.category,
                  course.category!,
                  AppColors.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20.sp, color: color),
        SizedBox(width: 6.w),
        Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
      ],
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
          ),
        ],
      ),
    );
  }

  Widget _buildContentsSection(List<CourseContent> contents, bool canAccess) {
    // Sort contents by displayOrder
    final sortedContents = List<CourseContent>.from(contents)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Content',
            style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 12.h),
          ...sortedContents.asMap().entries.map((entry) {
            final index = entry.key;
            final content = entry.value;
            return _buildContentItem(content, index + 1, canAccess);
          }),
        ],
      ),
    );
  }

  Widget _buildContentItem(CourseContent content, int index, bool canAccess) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContentTypeColor(content.contentType),
          child: Icon(
            _getContentTypeIcon(content.contentType),
            color: AppColors.white,
            size: 20.sp,
          ),
        ),
        title: Text(
          content.title ?? '${content.contentType.displayName} $index',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          content.contentType.displayName,
          style: AppTextStyles.caption,
        ),
        trailing: canAccess
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : const Icon(Icons.lock, color: AppColors.grey400),
        onTap: canAccess
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseContentViewerScreen(
                      course: _fullCourse ?? widget.course,
                      initialContentIndex: index - 1,
                    ),
                  ),
                );
              }
            : null,
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Course',
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Retry',
              onPressed: _loadCourseDetails,
              backgroundColor: AppColors.primary,
              width: 120.w,
            ),
          ],
        ),
      ),
    );
  }
}
