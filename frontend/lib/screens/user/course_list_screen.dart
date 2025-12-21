import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';
import 'course_detail_screen.dart';
import 'payment_instructions_screen.dart';

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
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = response.message ?? l10n.errorLoadingCourses;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = '${l10n.errorLoadingCourses} $e';
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

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.courses),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCourses),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorView()
            : _filteredCourses.isEmpty
            ? _buildEmptyView()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Section
                    _buildFilterSection(),
                    SizedBox(height: 16.h),
                    // Courses List
                    ..._filteredCourses.map(
                      (course) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _buildCourseCard(course, hasAccess),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final l10n = AppLocalizations.of(context);
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
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: Text(l10n.allCourses),
              selected: _selectedCourseType == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: FilterChip(
              label: Text(l10n.free),
              selected: _selectedCourseType == CourseType.free,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = selected ? CourseType.free : null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              checkmarkColor: AppColors.success,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: FilterChip(
              label: Text(l10n.paidCourse),
              selected: _selectedCourseType == CourseType.paid,
              onSelected: (selected) {
                setState(() {
                  _selectedCourseType = selected ? CourseType.paid : null;
                });
                _applyFilter();
              },
              selectedColor: AppColors.warning.withValues(alpha: 0.2),
              checkmarkColor: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool hasAccess) {
    final l10n = AppLocalizations.of(context);
    // Global payment: if user has access, they can access all paid courses
    final canAccess = course.isFree || hasAccess;

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
            // Course Image or Placeholder
            Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                color: AppColors.grey100,
              ),
              child:
                  course.courseImageUrl != null &&
                      course.courseImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
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
                                size: 48.sp,
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
                        size: 48.sp,
                        color: AppColors.grey400,
                      ),
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
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
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
                            fontSize: 11.sp,
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
                        l10n.contentCount(course.contentCount ?? 0),
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
                    text: canAccess ? l10n.viewCourse : l10n.getAccess,
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
                        // Navigate to payment instructions for global access
                        // Once user pays, they get access to ALL paid courses
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PaymentInstructionsScreen(),
                          ),
                        );
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              l10n.errorLoadingCourses,
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? l10n.unknownErrorOccurred,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: l10n.retry,
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              l10n.noCoursesAvailable,
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.checkBackLaterForNewCourses,
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
