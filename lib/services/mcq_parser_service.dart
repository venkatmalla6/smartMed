import '../models/mcq.dart';

class McqParserService {
  /// Attempts to parse MCQs from raw text using Regex.
  /// Returns a list of deduplicated, parsed questions.
  /// Falls back gracefully for MCQs that have no explicit "Answer:" line
  /// by accepting the first option as a placeholder — caller can still
  /// display them; AI fallback is only triggered when zero questions parse.
  static List<McqQuestion> parseFromText(String text) {
    final List<McqQuestion> parsedQuestions = [];

    // Normalise line endings
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 1. Identify where each question starts.
    // Matches: "1.", "1)", "Q1:", "Q1.", "Question 1:", etc.
    final qMarker = RegExp(
      r'^[ \t]*(?:Q(?:uestion)?\s*\d+|\d+)\s*[\.)\-:]\s+',
      caseSensitive: false,
      multiLine: true,
    );

    final matches = qMarker.allMatches(text).toList();

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].end;
      final end =
          (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final block = text.substring(start, end).trim();

      if (block.isNotEmpty) {
        final mcq = _parseSingleBlock(block);
        if (mcq != null) {
          // Deduplicate using normalised question text
          final norm = _normalize(mcq.question);
          if (!parsedQuestions.any((q) => _normalize(q.question) == norm)) {
            parsedQuestions.add(mcq);
          }
        }
      }
    }

    return parsedQuestions;
  }

  static McqQuestion? _parseSingleBlock(String block) {
    // 2. Separate the question text from the options.
    // Options start with: A., A), (A), a., a), (a)
    final optStartPattern = RegExp(
      r'(?:^|\n)[ \t]*(?:[A-D][\.\)]|\([A-D]\))[ \t]+',
      caseSensitive: false,
    );

    final optStartMatch = optStartPattern.firstMatch(block);
    if (optStartMatch == null) return null; // No options found

    final questionText = block.substring(0, optStartMatch.start).trim();
    if (questionText.isEmpty) return null;

    final remainder = block.substring(optStartMatch.start).trim();

    // 3. Extract the answer — OPTIONAL; if missing we accept the question anyway
    // Looks for "Answer: A", "Ans: (B)", "Correct Answer: c", "Correct: D", etc.
    final ansPattern = RegExp(
      r'(?:Correct\s+Answer|Answer|Ans\.?|Correct)\s*[:\-]?\s*[\(]?([A-D])[\)]?(?:[.\s]|$)',
      caseSensitive: false,
    );

    final ansMatch = ansPattern.firstMatch(remainder);
    String rawAnswerLetter = '';
    String optionsText = remainder;

    if (ansMatch != null) {
      rawAnswerLetter = (ansMatch.group(1) ?? '').toUpperCase();
      optionsText = remainder.substring(0, ansMatch.start).trim();
    }

    // 4. Parse the options (A, B, C, D)
    final Iterable<RegExpMatch> optMatches =
        optStartPattern.allMatches(optionsText);
    final List<String> parsedOptions = [];
    final List<String> letters = [];

    int prevEnd = -1;
    String prevLetter = '';

    for (final m in optMatches) {
      if (prevEnd != -1) {
        final optStr = optionsText.substring(prevEnd, m.start).trim();
        parsedOptions.add('$prevLetter. $optStr');
      }

      // Extract the letter from the match (A/B/C/D)
      final letterMatch =
          RegExp(r'[A-D]', caseSensitive: false).firstMatch(m.group(0)!);
      prevLetter = (letterMatch?.group(0) ?? '').toUpperCase();
      letters.add(prevLetter);
      prevEnd = m.end;
    }

    if (prevEnd != -1) {
      final lastOptStr = optionsText.substring(prevEnd).trim();
      parsedOptions.add('$prevLetter. $lastOptStr');
    }

    // Must have exactly 4 options to be a valid MCQ
    if (parsedOptions.length != 4) return null;

    // 5. Determine the correct answer string
    String finalAnswerStr = '';
    if (rawAnswerLetter.isNotEmpty) {
      final ansIndex = letters.indexOf(rawAnswerLetter);
      if (ansIndex != -1 && ansIndex < parsedOptions.length) {
        finalAnswerStr = parsedOptions[ansIndex];
      }
    }

    // If no answer found, default to option A (so question is still usable)
    if (finalAnswerStr.isEmpty) {
      finalAnswerStr = parsedOptions.first;
    }

    return McqQuestion(
      question: questionText.replaceAll('\n', ' ').trim(),
      options:
          parsedOptions.map((e) => e.replaceAll('\n', ' ').trim()).toList(),
      answer: finalAnswerStr.replaceAll('\n', ' ').trim(),
    );
  }

  /// Normalises a string for deduplication:
  /// lowercases, collapses whitespace, strips punctuation.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
