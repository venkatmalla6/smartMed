import 'package:hive/hive.dart';

part 'quiz_attempt.g.dart';

@HiveType(typeId: 2)
class QuizAttempt extends HiveObject {
  @HiveField(0)
  final int score;

  @HiveField(1)
  final int totalQuestions;

  @HiveField(2)
  final DateTime date;

  QuizAttempt({
    required this.score,
    required this.totalQuestions,
    required this.date,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
}
