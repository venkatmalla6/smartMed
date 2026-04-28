import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import '../services/hive_service.dart';
import '../services/mcq_parser_service.dart';
import '../screens/quiz_screen.dart';
import '../models/mcq.dart';

/// Shared logic to prompt for an API key (if missing), call AI,
/// and navigate to the QuizScreen. Call this from any screen that has text.
Future<void> launchQuizGeneration({
  required BuildContext context,
  required String text,
  required String sourceTitle,
}) async {
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No text available to generate a quiz from.')),
    );
    return;
  }

  if (!context.mounted) return;
  _showLoadingOverlay(context);

  try {
    // 1. Hybrid approach: Try to parse MCQs locally using Regex
    List<McqQuestion> questions = McqParserService.parseFromText(text);

    // 2. If no MCQs found locally, fallback to AI generation
    if (questions.isEmpty) {
      final service = GroqService();
      questions = await service.generateMcqs(text);
    }

    // Deduplicate questions
    final seenQuestions = <String>{};
    final uniqueQuestions = <McqQuestion>[];
    for (var q in questions) {
      final normalized = q.question.trim().toLowerCase();
      if (!seenQuestions.contains(normalized)) {
        seenQuestions.add(normalized);
        uniqueQuestions.add(q);
      }
    }
    questions = uniqueQuestions;

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          sourceTitle: sourceTitle,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────

void _showLoadingOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Generating Quiz…',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Asking Gemini AI, please wait.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
