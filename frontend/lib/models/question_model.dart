import 'package:json_annotation/json_annotation.dart';

part 'question_model.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String examId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String difficulty;
  final int points;
  final String? imageUrl;
  final String? questionImgUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.examId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.difficulty,
    required this.points,
    this.imageUrl,
    this.questionImgUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  Question copyWith({
    String? id,
    String? examId,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    int? points,
    String? imageUrl,
    String? questionImgUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      questionImgUrl: questionImgUrl ?? this.questionImgUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasQuestionImage =>
      questionImgUrl != null && questionImgUrl!.isNotEmpty;
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;

  bool get isEasy => difficulty == 'EASY';
  bool get isMedium => difficulty == 'MEDIUM';
  bool get isHard => difficulty == 'HARD';
}

@JsonSerializable()
class QuestionAnswer {
  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int timeSpent;

  QuestionAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeSpent,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnswerToJson(this);
}

@JsonSerializable()
class QuestionStats {
  final String questionId;
  final String difficulty;
  final int points;
  final int totalAttempts;
  final int correctAnswers;
  final double accuracy;

  QuestionStats({
    required this.questionId,
    required this.difficulty,
    required this.points,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracy,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) =>
      _$QuestionStatsFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionStatsToJson(this);
}

@JsonSerializable()
class BulkQuestionUpload {
  final String examId;
  final List<Question> questions;

  BulkQuestionUpload({
    required this.examId,
    required this.questions,
  });

  factory BulkQuestionUpload.fromJson(Map<String, dynamic> json) =>
      _$BulkQuestionUploadFromJson(json);
  Map<String, dynamic> toJson() => _$BulkQuestionUploadToJson(this);
}

@JsonSerializable()
class QuestionTemplate {
  final String examId;
  final String title;
  final String description;
  final List<Map<String, dynamic>> questions;

  QuestionTemplate({
    required this.examId,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) =>
      _$QuestionTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionTemplateToJson(this);
}
