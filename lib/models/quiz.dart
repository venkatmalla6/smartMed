import 'package:hive/hive.dart';
import 'mcq.dart';
import 'quiz_attempt.dart';

part 'quiz.g.dart';

@HiveType(typeId: 3)
class Quiz extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<McqQuestion> questions;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final List<QuizAttempt> attempts;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.createdAt,
    List<QuizAttempt>? attempts,
  }) : attempts = attempts ?? [];

  int get totalQuestions => questions.length;
  
  int get bestScore {
    if (attempts.isEmpty) return 0;
    return attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
  }

  void addAttempt(QuizAttempt attempt) {
    attempts.add(attempt);
    save();
  }
}
