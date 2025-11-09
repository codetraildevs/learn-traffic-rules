import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import 'create_course_screen.dart';
import 'edit_course_screen.dart';

class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() =>
      _CourseManagementScreenState();
}

class _CourseManagementScreenState extends ConsumerState<CourseManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedCategory;
  String? _selectedDifficulty;
  CourseType? _selectedCourseType;
  bool? _selectedIsActive;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseProvider.notifier).loadCourses();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(courseProvider.notifier).loadCourses();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 200.h,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Course Management',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                    fontSize: 20.sp,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50.h,
                        right: -50.w,
                        child: Container(
                          width: 200.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 48.sp,
                              color: AppColors.white,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Manage Learning Courses',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.white),
                  onPressed: () => _navigateToCreateCourse(),
                ),
              ],
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Statistics',
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filters
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: _buildFilters(),
                  ),
                ),
              ),
            ),

            // Loading State
            if (courseState.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),

            // Error State
            if (courseState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.error),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            courseState.error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.read(courseProvider.notifier).loadCourses(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Empty State
            if (_getFilteredCourses(courseState.courses).isEmpty &&
                !courseState.isLoading &&
                courseState.error == null)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 80.sp,
                            color: AppColors.grey400,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Courses Yet',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Create your first course to get started',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey500,
                            ),
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
                    ),
                  ),
                ),
              ),

            // Courses List
            if (_getFilteredCourses(courseState.courses).isNotEmpty &&
                !courseState.isLoading &&
                courseState.error == null)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Courses List',
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
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
                    ),
                  ),
                ),
              ),

            // Courses Grid
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final filteredCourses = _getFilteredCourses(
                    courseState.courses,
                  );
                  final course = filteredCourses[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildCourseCard(course, index),
                    ),
                  );
                }, childCount: _getFilteredCourses(courseState.courses).length),
              ),
            ),

            // Bottom Padding
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 20.sp,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1),
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
              _buildFilterChip('All Categories', _selectedCategory == null, () {
                setState(() => _selectedCategory = null);
              }),
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

  Widget _buildCourseCard(Course course, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 70.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: course.isActive
                      ? [AppColors.primary, AppColors.secondary]
                      : [AppColors.grey400, AppColors.grey500],
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                course.title,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      course.courseType.displayName,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.white,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      course.difficultyDisplay,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.white,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: course.isActive
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.description != null) ...[
                    Text(
                      course.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                  ],

                  // Stats row
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

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: () => _navigateToEditCourse(course),
                          backgroundColor: AppColors.primary,
                          textColor: AppColors.white,
                          height: 40.h,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: CustomButton(
                          text: course.isActive ? 'Deactivate' : 'Activate',
                          onPressed: () => _toggleCourseStatus(course),
                          backgroundColor: course.isActive
                              ? AppColors.grey500
                              : AppColors.success,
                          textColor: AppColors.white,
                          height: 40.h,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(course),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
      MaterialPageRoute(builder: (context) => EditCourseScreen(course: course)),
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
                    this.context,
                    'Course deleted successfully',
                  );
                } else {
                  if (!mounted) return;
                  AppFlashMessage.showError(
                    this.context,
                    'Failed to delete course',
                  );
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
