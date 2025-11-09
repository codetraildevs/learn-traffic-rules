import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

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

  CourseNotifier() : super(CourseState()) {
    loadCourses();
  }

  Future<void> loadCourses({
    String? category,
    String? difficulty,
    CourseType? courseType,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _courseService.getAllCourses(
        category: category,
        difficulty: difficulty,
        courseType: courseType,
        isActive: isActive,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(courses: response.data!, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load courses',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading courses: $e',
      );
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
