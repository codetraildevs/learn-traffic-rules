import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import 'create_course_screen.dart';
import 'course_detail_management_screen.dart';

class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() =>
      _CourseManagementScreenState();
}

class _CourseManagementScreenState
    extends ConsumerState<CourseManagementScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;
  CourseType? _selectedCourseType;
  bool? _selectedIsActive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseProvider.notifier).loadCourses();
      }
    });
  }

  List<Course> _getFilteredCourses(List<Course> courses) {
    return courses.where((course) {
      if (_selectedCategory != null &&
          course.category?.toLowerCase() != _selectedCategory?.toLowerCase()) {
        return false;
      }
      if (_selectedDifficulty != null &&
          course.difficulty.toLowerCase() !=
              _selectedDifficulty?.toLowerCase()) {
        return false;
      }
      if (_selectedCourseType != null &&
          course.courseType != _selectedCourseType) {
        return false;
      }
      if (_selectedIsActive != null && course.isActive != _selectedIsActive) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateCourse(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(courseProvider.notifier).loadCourses(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(courseProvider.notifier).loadCourses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsSection(courseState),

              SizedBox(height: 16.h),

              // Filters
              _buildFilters(),

              SizedBox(height: 16.h),

              // Loading State
              if (courseState.isLoading)
                const Center(child: CircularProgressIndicator()),

              // Error State
              if (courseState.error != null && !courseState.isLoading)
                _buildErrorView(courseState.error!),

              // Empty State
              if (_getFilteredCourses(courseState.courses).isEmpty &&
                  !courseState.isLoading &&
                  courseState.error == null)
                _buildEmptyView(),

              // Courses List
              if (_getFilteredCourses(courseState.courses).isNotEmpty &&
                  !courseState.isLoading &&
                  courseState.error == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Courses List',
                      style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                    ),
                    Text(
                      '${_getFilteredCourses(courseState.courses).length} ${_getFilteredCourses(courseState.courses).length == 1 ? 'course' : 'courses'}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ..._getFilteredCourses(courseState.courses).map((course) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildCourseCard(course),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateCourse(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
    );
  }

  Widget _buildStatsSection(CourseState courseState) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Courses',
            '${courseState.courses.length}',
            Icons.school,
            AppColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Active',
            '${courseState.courses.where((e) => e.isActive).length}',
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Free',
            '${courseState.courses.where((e) => e.isFree).length}',
            Icons.free_breakfast,
            AppColors.warning,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Paid',
            '${courseState.courses.where((e) => e.isPaid).length}',
            Icons.payment,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16.sp,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 10.sp),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
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
              Icon(Icons.filter_list, size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                'Filters',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildFilterChip(
                'All',
                _selectedCourseType == null && _selectedIsActive == null,
                () {
                  setState(() {
                    _selectedCourseType = null;
                    _selectedIsActive = null;
                  });
                },
              ),
              _buildFilterChip(
                'Free',
                _selectedCourseType == CourseType.free,
                () {
                  setState(
                    () => _selectedCourseType =
                        _selectedCourseType == CourseType.free
                        ? null
                        : CourseType.free,
                  );
                },
              ),
              _buildFilterChip(
                'Paid',
                _selectedCourseType == CourseType.paid,
                () {
                  setState(
                    () => _selectedCourseType =
                        _selectedCourseType == CourseType.paid
                        ? null
                        : CourseType.paid,
                  );
                },
              ),
              _buildFilterChip('Active', _selectedIsActive == true, () {
                setState(
                  () => _selectedIsActive = _selectedIsActive == true
                      ? null
                      : true,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(16.w),
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
                        course.title,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: course.isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.grey300.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              course.isActive ? 'Active' : 'Inactive',
                              style: AppTextStyles.caption.copyWith(
                                color: course.isActive
                                    ? AppColors.success
                                    : AppColors.grey600,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: course.isFree
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              course.courseType.displayName,
                              style: AppTextStyles.caption.copyWith(
                                color: course.isFree
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (course.description != null) ...[
              SizedBox(height: 8.h),
              Text(
                course.description!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildStatItem(
                  Icons.article,
                  '${course.contentCount ?? 0} Content',
                ),
                SizedBox(width: 8.w),
                if (course.category != null)
                  _buildStatItem(Icons.category, course.category!),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View',
                    onPressed: () => _navigateToEditCourse(course),
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                    height: 36.h,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomButton(
                    text: course.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleCourseStatus(course),
                    backgroundColor: course.isActive
                        ? AppColors.grey500
                        : AppColors.success,
                    textColor: AppColors.white,
                    height: 36.h,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _showDeleteDialog(course),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primary),
          SizedBox(width: 3.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey700,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppColors.error),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(courseProvider.notifier).loadCourses(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      padding: EdgeInsets.all(32.w),
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
        children: [
          Icon(Icons.school_outlined, size: 64.sp, color: AppColors.grey400),
          SizedBox(height: 16.h),
          Text(
            'No Courses Yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
          ),
          SizedBox(height: 6.h),
          Text(
            'Create your first course to get started',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Create Course',
            onPressed: () => _navigateToCreateCourse(),
            width: 200.w,
          ),
        ],
      ),
    );
  }

  void _navigateToCreateCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
    ).then((_) {
      ref.read(courseProvider.notifier).loadCourses();
    });
  }

  void _navigateToEditCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailManagementScreen(course: course),
      ),
    ).then((_) {
      ref.read(courseProvider.notifier).loadCourses();
    });
  }

  void _toggleCourseStatus(Course course) async {
    final success = await ref
        .read(courseProvider.notifier)
        .updateCourse(
          course.id,
          UpdateCourseRequest(isActive: !course.isActive),
        );
    if (mounted) {
      if (success) {
        AppFlashMessage.showSuccess(
          context,
          'Course ${course.isActive ? 'deactivated' : 'activated'} successfully',
        );
      } else {
        AppFlashMessage.showError(
          context,
          'Failed to ${course.isActive ? 'deactivate' : 'activate'} course',
        );
      }
    }
  }

  void _showDeleteDialog(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(courseProvider.notifier)
                  .deleteCourse(course.id);
              if (mounted) {
                if (success) {
                  if (!mounted) return;
                  AppFlashMessage.showSuccess(
                    context,
                    'Course deleted successfully',
                  );
                } else {
                  if (!mounted) return;
                  AppFlashMessage.showError(context, 'Failed to delete course');
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
