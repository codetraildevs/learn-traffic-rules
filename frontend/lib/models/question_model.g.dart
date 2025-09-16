// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
      id: json['id'] as String,
      examId: json['examId'] as String,
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String,
      points: (json['points'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      questionImgUrl: json['questionImgUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
      'id': instance.id,
      'examId': instance.examId,
      'question': instance.question,
      'options': instance.options,
      'correctAnswer': instance.correctAnswer,
      'explanation': instance.explanation,
      'difficulty': instance.difficulty,
      'points': instance.points,
      'imageUrl': instance.imageUrl,
      'questionImgUrl': instance.questionImgUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

QuestionAnswer _$QuestionAnswerFromJson(Map<String, dynamic> json) =>
    QuestionAnswer(
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeSpent: (json['timeSpent'] as num).toInt(),
    );

Map<String, dynamic> _$QuestionAnswerToJson(QuestionAnswer instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedAnswer': instance.selectedAnswer,
      'isCorrect': instance.isCorrect,
      'timeSpent': instance.timeSpent,
    };

QuestionStats _$QuestionStatsFromJson(Map<String, dynamic> json) =>
    QuestionStats(
      questionId: json['questionId'] as String,
      difficulty: json['difficulty'] as String,
      points: (json['points'] as num).toInt(),
      totalAttempts: (json['totalAttempts'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
    );

Map<String, dynamic> _$QuestionStatsToJson(QuestionStats instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'difficulty': instance.difficulty,
      'points': instance.points,
      'totalAttempts': instance.totalAttempts,
      'correctAnswers': instance.correctAnswers,
      'accuracy': instance.accuracy,
    };

BulkQuestionUpload _$BulkQuestionUploadFromJson(Map<String, dynamic> json) =>
    BulkQuestionUpload(
      examId: json['examId'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BulkQuestionUploadToJson(BulkQuestionUpload instance) =>
    <String, dynamic>{
      'examId': instance.examId,
      'questions': instance.questions,
    };

QuestionTemplate _$QuestionTemplateFromJson(Map<String, dynamic> json) =>
    QuestionTemplate(
      examId: json['examId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$QuestionTemplateToJson(QuestionTemplate instance) =>
    <String, dynamic>{
      'examId': instance.examId,
      'title': instance.title,
      'description': instance.description,
      'questions': instance.questions,
    };
