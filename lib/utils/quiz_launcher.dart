import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import '../services/mcq_parser_service.dart';
import '../services/extraction_service.dart';
import '../screens/quiz_screen.dart';
import '../models/mcq.dart';

/// Shared logic to parse/generate MCQs and navigate to the QuizScreen.
///
/// Strategy:
///   1. Try local regex parse first (instant — no network).
///   2. Only call Groq AI if regex finds zero questions.
///   3. Show a loading dialog ONLY when the AI call is needed.
Future<void> launchQuizGeneration({
  required BuildContext context,
  required String text,
  required String sourceTitle,
}) async {
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('No text available to generate a quiz from.')),
    );
    return;
  }

  // ── Step 1: instant local parse ──────────────────────────────────────────
  List<McqQuestion> questions = McqParserService.parseFromText(text);
  questions = _deduplicate(questions);

  if (questions.isNotEmpty) {
    // Regex found everything — navigate immediately, no loading needed
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(questions: questions, sourceTitle: sourceTitle),
      ),
    );
    return;
  }

  // ── Step 2: AI fallback (show loader) ────────────────────────────────────
  if (!context.mounted) return;
  _showLoadingOverlay(context);

  try {
    final service = GroqService();
    questions = await service.generateMcqs(text);
    questions = _deduplicate(questions);

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not extract questions. Try providing more structured text.'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(questions: questions, sourceTitle: sourceTitle),
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

/// Removes duplicate questions using normalised text comparison.
List<McqQuestion> _deduplicate(List<McqQuestion> questions) {
  final seen = <String>{};
  final unique = <McqQuestion>[];
  for (final q in questions) {
    final key = q.question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (seen.add(key)) unique.add(q);
  }
  return unique;
}

// ── Private helpers ──────────────────────────────────────────────────────────

/// Helper method to extract text from a PDF file, then launch the quiz generator.
Future<void> launchQuizGenerationFromPdf({
  required BuildContext context,
  required String path,
}) async {
  _showLoadingOverlay(context);
  try {
    final svc = ExtractionService();
    final text = await svc.extractTextFromPdf(path);
    svc.dispose();
    
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading
    
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text could be extracted from the PDF.')),
      );
      return;
    }
    
    // Pass extracted text to the main generation pipeline
    await launchQuizGeneration(
      context: context,
      text: text,
      sourceTitle: 'PDF Quiz',
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

/// Helper method to generate a quiz specifically from a short topic description.
Future<void> launchQuizGenerationFromTopic({
  required BuildContext context,
  required String topic,
}) async {
  if (topic.trim().isEmpty) return;
  
  _showLoadingOverlay(context);
  try {
    final service = GroqService();
    final questions = await service.generateTopicMcqs(topic);
    
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(questions: questions, sourceTitle: 'Topic: $topic'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

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
                    'Asking Groq AI, please wait.',
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
