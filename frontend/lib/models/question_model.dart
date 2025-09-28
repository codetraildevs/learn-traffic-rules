import 'package:json_annotation/json_annotation.dart';

part 'question_model.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String? examId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int points;
  final String? questionImgUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Question({
    required this.id,
    this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.points,
    this.questionImgUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}
