import 'package:json_annotation/json_annotation.dart';
import 'question_model.dart';

part 'exam_model.g.dart';

@JsonSerializable()
class Exam {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int duration;
  final int questionCount;
  final int passingScore;
  final String? examImgUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Question>? questions;

  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.questionCount,
    required this.passingScore,
    this.examImgUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.questions,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
  Map<String, dynamic> toJson() => _$ExamToJson(this);

  Exam copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? duration,
    int? questionCount,
    int? passingScore,
    String? examImgUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Question>? questions,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      questionCount: questionCount ?? this.questionCount,
      passingScore: passingScore ?? this.passingScore,
      examImgUrl: examImgUrl ?? this.examImgUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
    );
  }

  bool get isEasy => difficulty == 'EASY';
  bool get isMedium => difficulty == 'MEDIUM';
  bool get isHard => difficulty == 'HARD';
}

@JsonSerializable()
class ExamResult {
  final String id;
  final String userId;
  final String examId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final Map<String, String> answers;
  final bool passed;
  final DateTime completedAt;
  final Exam? exam;

  ExamResult({
    required this.id,
    required this.userId,
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.answers,
    required this.passed,
    required this.completedAt,
    this.exam,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) =>
      _$ExamResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExamResultToJson(this);

  ExamResult copyWith({
    String? id,
    String? userId,
    String? examId,
    double? score,
    int? totalQuestions,
    int? correctAnswers,
    int? timeSpent,
    Map<String, String>? answers,
    bool? passed,
    DateTime? completedAt,
    Exam? exam,
  }) {
    return ExamResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeSpent: timeSpent ?? this.timeSpent,
      answers: answers ?? this.answers,
      passed: passed ?? this.passed,
      completedAt: completedAt ?? this.completedAt,
      exam: exam ?? this.exam,
    );
  }

  double get percentage => (score / 100) * 100;
  int get incorrectAnswers => totalQuestions - correctAnswers;
  Duration get duration => Duration(seconds: timeSpent);
}

@JsonSerializable()
class ExamSubmission {
  final String examId;
  final Map<String, String> answers;
  final int timeSpent;

  ExamSubmission({
    required this.examId,
    required this.answers,
    required this.timeSpent,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) =>
      _$ExamSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$ExamSubmissionToJson(this);
}

@JsonSerializable()
class OfflineExamData {
  final Exam exam;
  final List<Question> questions;
  final DateTime downloadedAt;
  final int version;

  OfflineExamData({
    required this.exam,
    required this.questions,
    required this.downloadedAt,
    required this.version,
  });

  factory OfflineExamData.fromJson(Map<String, dynamic> json) =>
      _$OfflineExamDataFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineExamDataToJson(this);
}

@JsonSerializable()
class OfflineExamResult {
  final String examId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final Map<String, String> answers;
  final bool passed;
  final DateTime completedAt;
  final bool synced;

  OfflineExamResult({
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.answers,
    required this.passed,
    required this.completedAt,
    this.synced = false,
  });

  factory OfflineExamResult.fromJson(Map<String, dynamic> json) =>
      _$OfflineExamResultFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineExamResultToJson(this);

  OfflineExamResult copyWith({
    String? examId,
    double? score,
    int? totalQuestions,
    int? correctAnswers,
    int? timeSpent,
    Map<String, String>? answers,
    bool? passed,
    DateTime? completedAt,
    bool? synced,
  }) {
    return OfflineExamResult(
      examId: examId ?? this.examId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeSpent: timeSpent ?? this.timeSpent,
      answers: answers ?? this.answers,
      passed: passed ?? this.passed,
      completedAt: completedAt ?? this.completedAt,
      synced: synced ?? this.synced,
    );
  }
}
