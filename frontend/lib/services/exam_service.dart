import '../models/question_model.dart' as question_model;
import '../models/exam_result_model.dart';
import '../models/exam_model.dart';
import 'api_service.dart';

class ExamService {
  final ApiService _apiService = ApiService();

  Future<List<question_model.Question>> getQuestionsByExamId(
    String examId,
  ) async {
    try {
      print('🔍 FRONTEND DEBUG - Getting questions for exam: $examId');
      print('   API endpoint: /exams/$examId/take-exam');

      // Initialize ApiService to load stored tokens
      await _apiService.initialize();
      final headers = _apiService.getHeaders();
      print(
        '   ApiService initialized, token available: ${headers.containsKey('Authorization')}',
      );
      print('   Headers: $headers');
      if (headers.containsKey('Authorization')) {
        print('   Auth token: ${headers['Authorization']}');
      }

      final response = await _apiService.makeRequest(
        'GET',
        '/exams/$examId/take-exam',
      );

      print('🔍 FRONTEND DEBUG - API Response received:');
      print('   Response type: ${response.runtimeType}');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');
      print('   Data type: ${response['data']?.runtimeType}');
      print(
        '   Data length: ${response['data'] is List ? (response['data'] as List).length : 'Not a list'}',
      );

      if (response['success'] == true) {
        final questionsData = response['data'] as List<dynamic>;
        print('   Questions data length: ${questionsData.length}');

        if (questionsData.isNotEmpty) {
          print('   First question sample: ${questionsData[0]}');
        }

        final questions = questionsData
            .map(
              (questionJson) => question_model.Question.fromJson(
                questionJson as Map<String, dynamic>,
              ),
            )
            .toList();

        print('✅ Successfully parsed ${questions.length} questions');
        return questions;
      } else {
        print('❌ API returned error: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to load questions');
      }
    } catch (e) {
      print('❌ FRONTEND ERROR: $e');
      throw Exception('Error loading questions: $e');
    }
  }

  Future<ExamResultResponse> submitExamResult({
    required String examId,
    required Map<String, String> answers,
    required int timeSpent,
    required bool isFreeExam,
  }) async {
    try {
      print('🔍 FRONTEND DEBUG - Submitting exam result:');
      print('   Exam ID: $examId');
      print('   Answers: $answers');
      print('   Time Spent: $timeSpent');
      print('   Is Free Exam: $isFreeExam');

      final response = await _apiService.makeRequest(
        'POST',
        '/exams/submit-result',
        body: {
          'examId': examId,
          'answers': answers,
          'timeSpent': timeSpent,
          'isFreeExam': isFreeExam,
        },
      );

      if (response['success'] == true) {
        return ExamResultResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to submit exam');
      }
    } catch (e) {
      throw Exception('Error submitting exam: $e');
    }
  }

  Future<List<ExamResultData>> getUserExamResults() async {
    try {
      await _apiService.initialize();

      final response = await _apiService.makeRequest(
        'GET',
        '/exams/user-results',
      );

      if (response['success'] == true) {
        final resultsData = response['data'] as List<dynamic>;
        return resultsData
            .map(
              (resultJson) =>
                  ExamResultData.fromJson(resultJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load exam results');
      }
    } catch (e) {
      throw Exception('Error loading exam results: $e');
    }
  }

  Future<List<Exam>> getAvailableExams() async {
    try {
      await _apiService.initialize();

      final response = await _apiService.makeRequest('GET', '/exams');

      if (response['success'] == true) {
        final examsData = response['data'] as List<dynamic>;
        return examsData
            .map((examJson) => Exam.fromJson(examJson as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load exams');
      }
    } catch (e) {
      throw Exception('Error loading exams: $e');
    }
  }
}
