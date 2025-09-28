// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamResultResponse _$ExamResultResponseFromJson(Map<String, dynamic> json) =>
    ExamResultResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : ExamResultData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExamResultResponseToJson(ExamResultResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ExamResultData _$ExamResultDataFromJson(Map<String, dynamic> json) =>
    ExamResultData(
      id: json['id'] as String,
      examId: json['examId'] as String,
      userId: json['userId'] as String,
      score: (json['score'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num).toInt(),
      passed: json['passed'] as bool,
      isFreeExam: json['isFreeExam'] as bool,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      Exam: json['Exam'] == null
          ? null
          : ExamInfo.fromJson(json['Exam'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExamResultDataToJson(ExamResultData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'examId': instance.examId,
      'userId': instance.userId,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'timeSpent': instance.timeSpent,
      'passed': instance.passed,
      'isFreeExam': instance.isFreeExam,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'questionResults': instance.questionResults,
      'Exam': instance.Exam,
    };

ExamInfo _$ExamInfoFromJson(Map<String, dynamic> json) => ExamInfo(
  id: json['id'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  difficulty: json['difficulty'] as String,
);

Map<String, dynamic> _$ExamInfoToJson(ExamInfo instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'difficulty': instance.difficulty,
};

QuestionResult _$QuestionResultFromJson(Map<String, dynamic> json) =>
    QuestionResult(
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String?,
      options: (json['options'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      userAnswer: json['userAnswer'] as String,
      userAnswerLetter: json['userAnswerLetter'] as String?,
      correctAnswer: json['correctAnswer'] as String,
      correctAnswerLetter: json['correctAnswerLetter'] as String?,
      isCorrect: json['isCorrect'] as bool,
      points: (json['points'] as num).toInt(),
      questionImgUrl: json['questionImgUrl'] as String?,
    );

Map<String, dynamic> _$QuestionResultToJson(QuestionResult instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'questionText': instance.questionText,
      'options': instance.options,
      'userAnswer': instance.userAnswer,
      'userAnswerLetter': instance.userAnswerLetter,
      'correctAnswer': instance.correctAnswer,
      'correctAnswerLetter': instance.correctAnswerLetter,
      'isCorrect': instance.isCorrect,
      'points': instance.points,
      'questionImgUrl': instance.questionImgUrl,
    };
