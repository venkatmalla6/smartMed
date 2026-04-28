import 'package:flutter/foundation.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../services/hive_service.dart';

class QuizProvider extends ChangeNotifier {
  List<Quiz> _quizzes = [];

  List<Quiz> get quizzes => _quizzes;

  QuizProvider() {
    loadQuizzes();
  }

  void loadQuizzes() {
    _quizzes = HiveService.getAllQuizzes();
    notifyListeners();
  }

  Future<void> addQuiz(Quiz quiz) async {
    await HiveService.addQuiz(quiz);
    loadQuizzes();
  }

  Future<void> deleteQuiz(String id) async {
    await HiveService.deleteQuiz(id);
    loadQuizzes();
  }

  Future<void> logAttempt(String quizId, QuizAttempt attempt) async {
    final quizIndex = _quizzes.indexWhere((q) => q.id == quizId);
    if (quizIndex != -1) {
      final quiz = _quizzes[quizIndex];
      quiz.addAttempt(attempt); // This will call save() on the HiveObject internally
      loadQuizzes(); // Refresh UI if needed
    }
  }
}
