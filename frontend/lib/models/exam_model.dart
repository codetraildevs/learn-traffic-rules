import 'package:json_annotation/json_annotation.dart';

part 'exam_model.g.dart';

@JsonSerializable()
class Exam {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final int duration;
  final int passingScore;
  final bool isActive;
  final String? examImgUrl;
  final int? questionCount;
  final bool? isFirstTwo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Exam({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.difficulty,
    required this.duration,
    required this.passingScore,
    required this.isActive,
    this.examImgUrl,
    this.questionCount,
    this.isFirstTwo,
    this.createdAt,
    this.updatedAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      duration: (json['duration'] as num?)?.toInt() ?? 30,
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 70,
      isActive: json['isActive'] as bool? ?? true,
      examImgUrl: json['examImgUrl'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
      isFirstTwo: json['isFirstTwo'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$ExamToJson(this);

  Exam copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? duration,
    int? passingScore,
    bool? isActive,
    String? examImgUrl,
    int? questionCount,
    bool? isFirstTwo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      passingScore: passingScore ?? this.passingScore,
      isActive: isActive ?? this.isActive,
      examImgUrl: examImgUrl ?? this.examImgUrl,
      questionCount: questionCount ?? this.questionCount,
      isFirstTwo: isFirstTwo ?? this.isFirstTwo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get difficultyDisplay {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 'Easy';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  String get durationDisplay {
    if (duration < 60) {
      return '$duration m';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return minutes > 0 ? '$hours h $minutes m' : '$hours h';
    }
  }

  String get statusDisplay => isActive ? 'Active' : 'Inactive';
}

@JsonSerializable()
class CreateExamRequest {
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final int duration;
  final int passingScore;
  final bool isActive;
  final String? examImgUrl;

  const CreateExamRequest({
    required this.title,
    this.description,
    this.category,
    required this.difficulty,
    required this.duration,
    required this.passingScore,
    required this.isActive,
    this.examImgUrl,
  });

  factory CreateExamRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateExamRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateExamRequestToJson(this);
}

@JsonSerializable()
class UpdateExamRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? difficulty;
  final int? duration;
  final int? passingScore;
  final bool? isActive;
  final String? examImgUrl;

  const UpdateExamRequest({
    this.title,
    this.description,
    this.category,
    this.difficulty,
    this.duration,
    this.passingScore,
    this.isActive,
    this.examImgUrl,
  });

  factory UpdateExamRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateExamRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateExamRequestToJson(this);
}

@JsonSerializable()
class ExamResponse {
  final bool success;
  final String? message;
  final Exam? data;

  const ExamResponse({required this.success, this.message, this.data});

  factory ExamResponse.fromJson(Map<String, dynamic> json) =>
      _$ExamResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExamResponseToJson(this);
}

@JsonSerializable()
class ExamListResponse {
  final bool success;
  final String? message;
  final List<Exam>? data;

  const ExamListResponse({required this.success, this.message, this.data});

  factory ExamListResponse.fromJson(Map<String, dynamic> json) =>
      _$ExamListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExamListResponseToJson(this);
}

@JsonSerializable()
class ExamSubmission {
  final String examId;
  final List<QuestionAnswer> answers;
  final int timeSpent; // in seconds

  const ExamSubmission({
    required this.examId,
    required this.answers,
    required this.timeSpent,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) =>
      _$ExamSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$ExamSubmissionToJson(this);
}

@JsonSerializable()
class Question {
  final String id;
  final String examId;
  final String question;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctAnswer;
  final int points;
  final String? questionImgUrl;

  const Question({
    required this.id,
    required this.examId,
    required this.question,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
    required this.points,
    this.questionImgUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  // Helper method to get all options as a list
  List<String> get options => [option1, option2, option3, option4];
}

@JsonSerializable()
class CreateQuestionRequest {
  final String question;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctAnswer;
  final String? questionImgUrl;
  final int points;

  const CreateQuestionRequest({
    required this.question,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
    this.questionImgUrl,
    this.points = 1,
  });

  factory CreateQuestionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateQuestionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateQuestionRequestToJson(this);
}

@JsonSerializable()
class QuestionAnswer {
  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;

  const QuestionAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnswerToJson(this);
}

@JsonSerializable()
class ExamResult {
  final String id;
  final String examId;
  final String userId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final bool passed;
  final DateTime completedAt;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.passed,
    required this.completedAt,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) =>
      _$ExamResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExamResultToJson(this);
}
