import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_model.dart';
import '../services/exam_api_service.dart';

enum ExamStatus { initial, loading, success, error }

class ExamState {
  final ExamStatus status;
  final List<Exam> exams;
  final String? error;
  final bool isLoading;

  const ExamState({
    this.status = ExamStatus.initial,
    this.exams = const [],
    this.error,
    this.isLoading = false,
  });

  ExamState copyWith({
    ExamStatus? status,
    List<Exam>? exams,
    String? error,
    bool? isLoading,
  }) {
    return ExamState(
      status: status ?? this.status,
      exams: exams ?? this.exams,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ExamNotifier extends StateNotifier<ExamState> {
  ExamNotifier() : super(const ExamState());

  final ExamApiService _examApiService = ExamApiService();

  /// Load all exams
  Future<void> loadExams() async {
    print('🔄 EXAM PROVIDER: Starting to load exams...');
    state = state.copyWith(status: ExamStatus.loading, isLoading: true);

    try {
      print('🔄 EXAM PROVIDER: Calling API service...');
      final exams = await _examApiService.getExams();
      print('🔄 EXAM PROVIDER: Received ${exams.length} exams from API');
      state = state.copyWith(
        status: ExamStatus.success,
        exams: exams,
        isLoading: false,
        error: null,
      );
      print('🔄 EXAM PROVIDER: State updated successfully');
    } catch (e) {
      print('❌ EXAM PROVIDER: Error loading exams: $e');
      state = state.copyWith(
        status: ExamStatus.error,
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Create new exam
  Future<bool> createExam(CreateExamRequest request) async {
    state = state.copyWith(isLoading: true);

    try {
      final newExam = await _examApiService.createExam(request);
      state = state.copyWith(
        exams: [...state.exams, newExam],
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update exam
  Future<bool> updateExam(String examId, UpdateExamRequest request) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedExam = await _examApiService.updateExam(examId, request);
      final updatedExams = state.exams.map((exam) {
        return exam.id == examId ? updatedExam : exam;
      }).toList();

      state = state.copyWith(
        exams: updatedExams,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Delete exam
  Future<bool> deleteExam(String examId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _examApiService.deleteExam(examId);
      final updatedExams = state.exams
          .where((exam) => exam.id != examId)
          .toList();

      state = state.copyWith(
        exams: updatedExams,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Toggle exam status
  Future<bool> toggleExamStatus(String examId) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedExam = await _examApiService.toggleExamStatus(examId);
      final updatedExams = state.exams.map((exam) {
        return exam.id == examId ? updatedExam : exam;
      }).toList();

      state = state.copyWith(
        exams: updatedExams,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final examProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) {
  return ExamNotifier();
});
