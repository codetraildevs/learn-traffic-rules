import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../services/network_service.dart';

class CourseState {
  final List<Course> courses;
  final bool isLoading;
  final String? error;

  CourseState({this.courses = const [], this.isLoading = false, this.error});

  CourseState copyWith({
    List<Course>? courses,
    bool? isLoading,
    String? error,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CourseNotifier extends StateNotifier<CourseState> {
  final CourseService _courseService = CourseService();
  final NetworkService _networkService = NetworkService();
  static const String _cacheKeyCourses = 'cached_courses';
  static const String _cacheKeyTimestamp = 'courses_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 1);

  CourseNotifier() : super(CourseState()) {
    loadCourses();
  }

  Future<void> loadCourses({
    String? category,
    String? difficulty,
    CourseType? courseType,
    bool? isActive,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Check internet connection
    final hasInternet = await _networkService.hasInternetConnection();

    // Try to load from cache first if offline or if cache is still valid
    if (!hasInternet || !forceRefresh) {
      final cachedCourses = await _loadCachedCourses();
      if (cachedCourses != null && !forceRefresh) {
        state = state.copyWith(
          courses: cachedCourses,
          isLoading: false,
          error: null,
        );
        // If offline, use cache and return
        if (!hasInternet) {
          return;
        }
        // If online but cache is valid, use cache and refresh in background
        if (await _isCacheValid()) {
          // Load fresh data in background
          _loadFreshCourses(category, difficulty, courseType, isActive);
          return;
        }
      }
    }

    // Load fresh data from API
    if (hasInternet) {
      try {
        final response = await _courseService.getAllCourses(
          category: category,
          difficulty: difficulty,
          courseType: courseType,
          isActive: isActive,
        );

        if (response.success && response.data != null) {
          state = state.copyWith(courses: response.data!, isLoading: false);
          // Cache the data
          await _cacheCourses(response.data!);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response.message ?? 'Failed to load courses',
          );
        }
      } catch (e) {
        // Try to load from cache on error
        final cachedCourses = await _loadCachedCourses();
        if (cachedCourses != null) {
          state = state.copyWith(
            courses: cachedCourses,
            isLoading: false,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Error loading courses: $e',
          );
        }
      }
    } else {
      // No internet and no cache - show error
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection and no cached data available',
      );
    }
  }

  Future<void> _loadFreshCourses(
    String? category,
    String? difficulty,
    CourseType? courseType,
    bool? isActive,
  ) async {
    try {
      final response = await _courseService.getAllCourses(
        category: category,
        difficulty: difficulty,
        courseType: courseType,
        isActive: isActive,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(courses: response.data!);
        await _cacheCourses(response.data!);
      }
    } catch (e) {
      // Silently fail - user already has cached data
    }
  }

  Future<void> _cacheCourses(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await prefs.setString(_cacheKeyCourses, jsonEncode(coursesJson));
      await prefs.setString(
        _cacheKeyTimestamp,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Course>?> _loadCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_cacheKeyCourses);
      if (coursesJson == null) return null;

      final coursesList = jsonDecode(coursesJson) as List;
      return coursesList
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheKeyTimestamp);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      return now.difference(timestamp) < _cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCourse(CreateCourseRequest request) async {
    try {
      final response = await _courseService.createCourse(request);
      if (response.success) {
        await loadCourses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCourse(
    String courseId,
    UpdateCourseRequest request,
  ) async {
    try {
      final response = await _courseService.updateCourse(courseId, request);
      if (response.success) {
        await loadCourses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      final success = await _courseService.deleteCourse(courseId);
      if (success) {
        await loadCourses();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>(
  (ref) => CourseNotifier(),
);
