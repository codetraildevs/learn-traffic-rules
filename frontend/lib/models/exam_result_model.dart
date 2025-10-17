import 'package:json_annotation/json_annotation.dart';

part 'exam_result_model.g.dart';

@JsonSerializable()
class ExamResultResponse {
  final bool success;
  final String message;
  final ExamResultData? data;

  const ExamResultResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ExamResultResponse.fromJson(Map<String, dynamic> json) {
    return ExamResultResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? ExamResultData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$ExamResultResponseToJson(this);
}

@JsonSerializable()
class ExamResultData {
  final String id;
  final String examId;
  final String userId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final bool passed;
  final bool isFreeExam;
  final DateTime submittedAt;
  final List<QuestionResult>? questionResults;
  final ExamInfo? exam;

  const ExamResultData({
    required this.id,
    required this.examId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.passed,
    required this.isFreeExam,
    required this.submittedAt,
    this.questionResults,
    this.exam,
  });

  factory ExamResultData.fromJson(Map<String, dynamic> json) {
    return ExamResultData(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      timeSpent: json['timeSpent'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      isFreeExam: json['isFreeExam'] as bool? ?? false,
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      questionResults: json['questionResults'] != null
          ? (json['questionResults'] as List<dynamic>)
                .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      exam: json['Exam'] != null
          ? ExamInfo.fromJson(json['Exam'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$ExamResultDataToJson(this);
}

@JsonSerializable()
class ExamInfo {
  final String id;
  final String title;
  final String category;
  final String difficulty;

  const ExamInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
  });

  factory ExamInfo.fromJson(Map<String, dynamic> json) {
    return ExamInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$ExamInfoToJson(this);
}

@JsonSerializable()
class QuestionResult {
  final String questionId;
  final String? questionText;
  final Map<String, String>? options;
  final String userAnswer;
  final String? userAnswerLetter;
  final String correctAnswer;
  final String? correctAnswerLetter;
  final bool isCorrect;
  final int points;
  final String? questionImgUrl;

  const QuestionResult({
    required this.questionId,
    this.questionText,
    this.options,
    required this.userAnswer,
    this.userAnswerLetter,
    required this.correctAnswer,
    this.correctAnswerLetter,
    required this.isCorrect,
    required this.points,
    this.questionImgUrl,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'] as String? ?? '',
      questionText: json['questionText'] as String?,
      options: json['options'] != null
          ? Map<String, String>.from(json['options'] as Map<String, dynamic>)
          : null,
      userAnswer: json['userAnswer'] as String? ?? '',
      userAnswerLetter: json['userAnswerLetter'] as String?,
      correctAnswer: json['correctAnswer'] as String? ?? '',
      correctAnswerLetter: json['correctAnswerLetter'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
      questionImgUrl: json['questionImgUrl'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$QuestionResultToJson(this);
}
