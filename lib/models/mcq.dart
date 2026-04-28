import 'dart:convert';
import 'package:hive/hive.dart';

part 'mcq.g.dart';

/// A single MCQ question with 4 options and a correct answer.
@HiveType(typeId: 1)
class McqQuestion extends HiveObject {
  @HiveField(0)
  final String question;
  
  @HiveField(1)
  final List<String> options; // Always 4 items: ["A. ...", "B. ...", ...]
  
  @HiveField(2)
  final String answer; // Must match one of the options exactly

  McqQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      question: (json['question'] as String? ?? '').trim(),
      options: List<String>.from(
        (json['options'] as List? ?? []).map((e) => e.toString().trim()),
      ),
      answer: (json['answer'] as String? ?? '').trim(),
    );
  }

  /// Safely parse a raw JSON string (possibly wrapped in markdown fences)
  /// into a list of [McqQuestion]. Returns [] on any failure.
  static List<McqQuestion> parseList(String raw) {
    try {
      String cleaned = raw.trim();

      // Strip markdown code fences like ```json ... ```
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();

      // Determine if it's an array or an object
      dynamic decoded;
      try {
        decoded = json.decode(cleaned);
      } catch (e) {
        // Fallback: extract the JSON array portion manually if it's wrapped in text
        final start = cleaned.indexOf('[');
        final end = cleaned.lastIndexOf(']');
        if (start != -1 && end != -1 && end > start) {
          cleaned = cleaned.substring(start, end + 1);
          decoded = json.decode(cleaned);
        } else {
          // Check for object format manually
          final oStart = cleaned.indexOf('{');
          final oEnd = cleaned.lastIndexOf('}');
          if (oStart != -1 && oEnd != -1 && oEnd > oStart) {
            cleaned = cleaned.substring(oStart, oEnd + 1);
            decoded = json.decode(cleaned);
          } else {
            return [];
          }
        }
      }

      List<dynamic> list = [];
      if (decoded is Map && decoded.containsKey('questions')) {
        list = decoded['questions'] as List<dynamic>;
      } else if (decoded is List) {
        list = decoded;
      }

      final questions = list
          .whereType<Map<String, dynamic>>()
          .map(McqQuestion.fromJson)
          .where((q) =>
              q.question.isNotEmpty &&
              q.options.length == 4 &&
              q.answer.isNotEmpty)
          .toList();

      return questions;
    } catch (_) {
      return [];
    }
  }
}
