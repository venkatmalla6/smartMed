import '../models/mcq.dart';

class McqParserService {
  /// Attempts to parse MCQs from raw text using Regex.
  /// Returns a list of parsed questions. If none or very few are found,
  /// the caller can decide to fallback to AI.
  static List<McqQuestion> parseFromText(String text) {
    final List<McqQuestion> parsedQuestions = [];

    // Clean up carriage returns
    text = text.replaceAll('\r\n', '\n');

    // 1. Identify where each question starts.
    // Matches lines starting with "1.", "1)", "Q1:", "Q1.", "Question 1:", etc.
    final qMarker = RegExp(
      r'^[ \t]*(?:Q(?:uestion)?\s*\d+|[0-9]+)\s*[\.\):-]\s+',
      caseSensitive: false,
      multiLine: true,
    );

    final matches = qMarker.allMatches(text).toList();

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final block = text.substring(start, end).trim();

      if (block.isNotEmpty) {
        final mcq = _parseSingleBlock(block);
        if (mcq != null) {
          // Prevent duplicate exact questions
          if (!parsedQuestions.any((q) => q.question == mcq.question)) {
            parsedQuestions.add(mcq);
          }
        }
      }
    }

    return parsedQuestions;
  }

  static McqQuestion? _parseSingleBlock(String block) {
    // 2. Separate the question text from the options and answer.
    // Options typically start with A., A), (A), a., etc.
    final optStartPattern = RegExp(
      r'(?:[A-D][\.\)]|\([A-D]\))\s+',
      caseSensitive: false,
    );

    final optStartMatch = optStartPattern.firstMatch(block);
    if (optStartMatch == null) return null; // No options found

    final questionText = block.substring(0, optStartMatch.start).trim();
    final remainder = block.substring(optStartMatch.start).trim();

    // 3. Extract the answer
    // Looks for "Answer: A", "Ans: (B)", "Correct Answer: c", etc.
    final ansPattern = RegExp(
      r'(?:Answer|Ans\.|Ans|Correct Answer)\s*[:\-]?\s*[\(]?([A-D])[\)]?(?:[\.\s]|$)',
      caseSensitive: false,
    );

    final ansMatch = ansPattern.firstMatch(remainder);
    String rawAnswerLetter = '';
    String optionsText = remainder;

    if (ansMatch != null) {
      rawAnswerLetter = (ansMatch.group(1) ?? '').toUpperCase();
      // Remove the answer line from the options text to parse options cleanly
      optionsText = remainder.substring(0, ansMatch.start).trim();
    }

    // 4. Parse the 4 options
    final Iterable<RegExpMatch> optMatches = optStartPattern.allMatches(optionsText);
    final List<String> parsedOptions = [];
    final List<String> letters = [];

    int prevStart = -1;
    String prevLetter = '';

    for (final m in optMatches) {
      if (prevStart != -1) {
        final optStr = optionsText.substring(prevStart, m.start).trim();
        parsedOptions.add('$prevLetter. $optStr');
      }

      final fullMatchStr = m.group(0)!;
      // Extract the exact letter used (A, B, C, D)
      final letterMatch = RegExp(r'[A-D]', caseSensitive: false).firstMatch(fullMatchStr);
      prevLetter = (letterMatch?.group(0) ?? '').toUpperCase();
      letters.add(prevLetter);

      prevStart = m.end;
    }

    if (prevStart != -1) {
      final lastOptStr = optionsText.substring(prevStart).trim();
      parsedOptions.add('$prevLetter. $lastOptStr');
    }

    if (parsedOptions.length != 4) {
      return null; // Strict requirement: must have exactly 4 options
    }

    // Determine correct answer string based on the extracted letter
    String finalAnswerStr = '';
    if (rawAnswerLetter.isNotEmpty) {
      final ansIndex = letters.indexOf(rawAnswerLetter);
      if (ansIndex != -1 && ansIndex < parsedOptions.length) {
        finalAnswerStr = parsedOptions[ansIndex];
      }
    }

    if (finalAnswerStr.isEmpty) {
      // Must have a clear answer to be a valid MCQ
      return null;
    }

    return McqQuestion(
      question: questionText.replaceAll('\n', ' ').trim(),
      options: parsedOptions.map((e) => e.replaceAll('\n', ' ').trim()).toList(),
      answer: finalAnswerStr.replaceAll('\n', ' ').trim(),
    );
  }
}
