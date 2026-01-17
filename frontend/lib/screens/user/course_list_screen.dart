import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_traffic_rules/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/network_service.dart';
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
  final NetworkService _networkService = NetworkService();
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String? _error;
  CourseType? _selectedCourseType;

  // Cache keys
  static const String _cacheKeyCourses = 'cached_courses';
  static const String _cacheKeyTimestamp = 'courses_cache_timestamp';

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Load from cache first, then fetch fresh data
    _loadCourses();
    // Pre-cache images in background
    ImageCacheService.instance.initialize();
  }

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    // OPTIMIZATION: Load from cache FIRST for instant display
    final cachedDataLoaded = await _loadCachedCourses();

    if (cachedDataLoaded && !forceRefresh) {
      // Show cached data immediately
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } else {
      // No cache or force refresh - show loading
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
    }

    // Check internet connection in parallel
    final hasInternetFuture = _networkService.hasInternetConnection();

    // If we have cached data, show it and fetch fresh data in background
    if (cachedDataLoaded && !forceRefresh) {
      final hasInternet = await hasInternetFuture;
      if (hasInternet) {
        // Fetch fresh data in background (non-blocking)
        _loadFreshCourses().catchError((e) {
          debugPrint('⚠️ Background course refresh failed: $e');
        });
      }
      return; // Exit early - UI already shown with cache
    }

    // No cache or force refresh - must wait for API
    final hasInternet = await hasInternetFuture;

    if (hasInternet) {
      try {
        final response = await _courseService.getAllCourses(isActive: true);
        if (response.success && response.data != null) {
          if (mounted) {
            setState(() {
              _courses = response.data!;
              _filteredCourses = _courses;
            });
            _applyFilter();
            // Cache the data
            await _cacheCourses(response.data!);
          }
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
        // Try to load from cache on error
        final cachedLoaded = await _loadCachedCourses();
        if (cachedLoaded) {
          setState(() {
            _error = null; // Clear error if cache loaded
          });
        } else {
          setState(() {
            _error = '${l10n.errorLoadingCourses} $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // No internet and no cache - show error
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (!cachedDataLoaded) {
          setState(() {
            _error = l10n.noInternetConnection;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadFreshCourses() async {
    try {
      final response = await _courseService.getAllCourses(isActive: true);
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _courses = response.data!;
            _filteredCourses = _courses;
          });
          _applyFilter();
          // Cache the data
          await _cacheCourses(response.data!);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading fresh courses: $e');
      // Silently fail - user already has cached data displayed
    }
  }

  Future<bool> _loadCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_cacheKeyCourses);

      if (coursesJson == null) {
        debugPrint('📦 No cached courses found');
        return false;
      }

      final coursesList = jsonDecode(coursesJson) as List;
      final cachedCourses = coursesList
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _courses = cachedCourses;
          _filteredCourses = _courses;
        });
        _applyFilter();
      }

      debugPrint('📦 Loaded ${cachedCourses.length} cached courses');
      return true;
    } catch (e) {
      debugPrint('Error loading cached courses: $e');
      return false;
    }
  }

  Future<void> _cacheCourses(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await prefs.setString(_cacheKeyCourses, jsonEncode(coursesJson));
      await prefs.setString(_cacheKeyTimestamp, DateTime.now().toIso8601String());

      // Pre-cache course images in background
      for (final course in courses) {
        if (course.courseImageUrl != null && course.courseImageUrl!.isNotEmpty) {
          final imageUrl = course.courseImageUrl!.startsWith('http')
              ? course.courseImageUrl!
              : '${AppConstants.baseUrlImage}${course.courseImageUrl}';
          ImageCacheService.instance.cacheImage(imageUrl).catchError((e) {
            debugPrint('⚠️ Failed to cache course image: $e');
            return null;
          });
        }
      }

      debugPrint('💾 Cached ${courses.length} courses');
    } catch (e) {
      debugPrint('Error caching courses: $e');
    }
  }

  void _applyFilter() {
    // OPTIMIZATION: Filter logic without setState (caller handles setState)
    if (_selectedCourseType == null) {
      _filteredCourses = _courses;
    } else {
      _filteredCourses = _courses
          .where((course) => course.courseType == _selectedCourseType)
          .toList();
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCourses(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCourses(forceRefresh: true),
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
                // OPTIMIZATION: Batch setState with filter
                setState(() {
                  _selectedCourseType = null;
                  _applyFilter();
                });
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
                // OPTIMIZATION: Batch setState with filter
                setState(() {
                  _selectedCourseType = selected ? CourseType.free : null;
                  _applyFilter();
                });
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
                // OPTIMIZATION: Batch setState with filter
                setState(() {
                  _selectedCourseType = selected ? CourseType.paid : null;
                  _applyFilter();
                });
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
                      child: FutureBuilder<String>(
                        future: ImageCacheService.instance.getImagePath(
                          course.courseImageUrl!.startsWith('http')
                              ? course.courseImageUrl!
                              : '${AppConstants.baseUrlImage}${course.courseImageUrl}',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              color: AppColors.grey100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          final imagePath = snapshot.data ?? '';
                          if (imagePath.isEmpty) {
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
                          }

                          return Image.network(
                            imagePath,
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
