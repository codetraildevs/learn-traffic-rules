import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String? _error;
  CourseType? _selectedCourseType;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _courseService.getAllCourses(isActive: true);
      if (response.success && response.data != null) {
        setState(() {
          _courses = response.data!;
          _filteredCourses = _courses;
        });
        _applyFilter();
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load courses';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading courses: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedCourseType == null) {
      setState(() {
        _filteredCourses = _courses;
      });
    } else {
      setState(() {
        _filteredCourses = _courses
            .where((course) => course.courseType == _selectedCourseType)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasAccess = authState.accessPeriod?.hasAccess ?? false;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorView()
            : _filteredCourses.isEmpty
            ? _buildEmptyView()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Filter Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: _buildFilterSection(),
                    ),
                  ),

                  // Courses List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final course = _filteredCourses[index];
                        return _buildCourseCard(course, hasAccess);
                      }, childCount: _filteredCourses.length),
                    ),
                  ),

                  // Bottom Padding
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('All Courses'),
              selected: _selectedCourseType == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = selected ? null : null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: FilterChip(
              label: const Text('Free'),
              selected: _selectedCourseType == CourseType.free,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = selected ? CourseType.free : null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.success.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: FilterChip(
              label: const Text('Paid'),
              selected: _selectedCourseType == CourseType.paid,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = selected ? CourseType.paid : null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.warning.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool hasAccess) {
    final canAccess = course.isFree || hasAccess;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            if (course.courseImageUrl != null &&
                course.courseImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                child: Image.network(
                  course.courseImageUrl!.startsWith('http')
                      ? course.courseImageUrl!
                      : '${AppConstants.baseUrlImage}${course.courseImageUrl}',
                  height: 200.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200.h,
                      color: AppColors.grey200,
                      child: Icon(
                        Icons.school,
                        size: 48.sp,
                        color: AppColors.grey400,
                      ),
                    );
                  },
                ),
              ),

            // Course Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
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
                          style: AppTextStyles.caption.copyWith(
                            color: course.isFree
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (course.description != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      course.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 12.h),

                  // Course Stats
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.article,
                        '${course.contentCount ?? 0} Content',
                        AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      _buildStatChip(
                        Icons.straighten,
                        course.difficultyDisplay,
                        AppColors.secondary,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Action Button
                  CustomButton(
                    text: canAccess ? 'View Course' : 'Get Access',
                    onPressed: () {
                      if (canAccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailScreen(course: course),
                          ),
                        );
                      } else {
                        // Show payment instructions
                        // Navigator.push to payment screen
                      }
                    },
                    backgroundColor: canAccess
                        ? AppColors.primary
                        : AppColors.warning,
                    textColor: AppColors.white,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
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
              'Error Loading Courses',
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
              onPressed: _loadCourses,
              backgroundColor: AppColors.primary,
              width: 120.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              'No Courses Available',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Check back later for new courses',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
