import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/mcq.dart';
import '../models/flashcard.dart';


class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Switched to llama-3.1-8b-instant which has a much higher TPM limit
  // (20,000 TPM) compared to llama-3.3-70b-versatile (12,000 TPM).
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt =
      'You are a smart educational quiz generator. '
      'Generate multiple choice questions strictly based on the provided text. '
      'IMPORTANT: You must output ONLY a valid JSON object with a single key "questions" containing an array of objects.\n'
      'Each object must have exactly these keys:\n'
      '  "question": the question string\n'
      '  "options": array of exactly 4 strings, each prefixed with "A. ", "B. ", "C. ", "D. "\n'
      '  "answer": must exactly match one of the options strings\n'
      'Extract and format EVERY SINGLE QUESTION found in the text. Do not stop early.\n';

  static const String _apiKey =
      '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';

  // Max retries on rate-limit errors
  static const int _maxRetries = 4;

  GroqService();

  Future<List<McqQuestion>> generateMcqs(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('No text provided for quiz generation.');
    }
    if (_apiKey.trim().isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception('Groq API key is not configured in the code.');
    }

    // Smaller chunks → fewer tokens per request → less chance of hitting TPM
    final List<String> chunks = _splitText(text, 3000);
    final List<McqQuestion> allQuestions = [];

    for (int i = 0; i < chunks.length; i++) {
      final questions = await _processChunkWithRetry(chunks[i]);
      allQuestions.addAll(questions);

      // Wait between chunks to spread load across the 1-minute TPM window
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    if (allQuestions.isEmpty) {
      throw Exception(
        'Could not parse quiz questions from the AI response.\n'
        'Try providing more detailed or longer text.',
      );
    }

    return _deduplicateQuestions(allQuestions);
  }

  List<McqQuestion> _deduplicateQuestions(List<McqQuestion> questions) {
    final Map<String, McqQuestion> uniqueMap = {};
    for (final q in questions) {
      final normalized = q.question.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
      if (!uniqueMap.containsKey(normalized)) {
        uniqueMap[normalized] = q;
      }
    }
    return uniqueMap.values.toList();
  }

  Future<List<McqQuestion>> generateTopicMcqs(String topic) async {
    if (topic.trim().isEmpty) {
      throw Exception('No topic provided for quiz generation.');
    }
    if (_apiKey.trim().isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception('Groq API key is not configured in the code.');
    }

    final systemPrompt = 'You are a smart educational quiz generator. '
        'Generate EXACTLY 20 multiple choice questions about the topic provided by the user. '
        'Ensure there are NO duplicate questions and the questions are highly relevant to the topic. '
        'IMPORTANT: You must output ONLY a valid JSON object with a single key "questions" containing an array of objects.\n'
        'Each object must have exactly these keys:\n'
        '  "question": the question string\n'
        '  "options": array of exactly 4 strings, each prefixed with "A. ", "B. ", "C. ", "D. "\n'
        '  "answer": must exactly match one of the options strings\n';

    final questions = await _processWithPromptAndRetry(topic, systemPrompt);

    if (questions.isEmpty) {
      throw Exception('Could not generate questions for this topic. Please try a different description.');
    }

    return _deduplicateQuestions(questions);
  }

  Future<List<McqQuestion>> _processWithPromptAndRetry(String input, String systemPrompt) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': input},
            ],
            'temperature': 0.7,
            'max_tokens': 4000,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          try {
            final parsed = _parseResponse(response.body);
            if (parsed.isNotEmpty) {
              return parsed;
            } else {
              print('Groq returned empty questions. Body: ${response.body}');
              throw Exception('Parsed questions were empty.');
            }
          } catch (e) {
            print('Error parsing Groq response: $e\nBody: ${response.body}');
            throw Exception('Error parsing response.');
          }
        } else if (response.statusCode == 429) {
          print('Groq rate limited. Retrying...');
          final delay = pow(2, attempt) + Random().nextDouble();
          await Future.delayed(Duration(seconds: delay.toInt()));
          continue;
        } else {
          print('Groq API error ${response.statusCode}: ${response.body}');
          throw Exception('Failed to generate quiz (Status ${response.statusCode})');
        }
      } catch (e) {
        print('Groq error on attempt $attempt: $e');
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return [];
  }

  /// Wraps [_processChunk] with exponential-backoff retry on HTTP 429.
  Future<List<McqQuestion>> _processChunkWithRetry(String chunk) async {
    int attempt = 0;
    while (true) {
      try {
        return await _processChunk(chunk);
      } on _RateLimitException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw Exception(
            'Rate limit exceeded after $_maxRetries attempts. '
            'Please wait a minute and try again.\nDetails: ${e.message}',
          );
        }
        // Wait the server-suggested time, or use exponential backoff
        final waitSeconds = e.retryAfterSeconds ?? _backoffSeconds(attempt);
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }
  }

  /// Exponential backoff: 2^attempt seconds (capped at 60s).
  int _backoffSeconds(int attempt) => min(60, pow(2, attempt).toInt());

  Future<List<McqQuestion>> _processChunk(String chunk) async {
    final uri = Uri.parse(_baseUrl);

    final requestBody = json.encode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': 'Text to extract quizzes from:\n$chunk'},
      ],
      'temperature': 0.1,
      'max_tokens': 4096,
      'response_format': {'type': 'json_object'},
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      // Parse retry-after header if available
      final retryAfter = _parseRetryAfter(response);
      String errorMsg = 'Rate limit reached.';
      try {
        final errorBody =
            json.decode(response.body) as Map<String, dynamic>;
        final apiError =
            (errorBody['error'] as Map<String, dynamic>?)?['message'];
        if (apiError != null) errorMsg = apiError as String;
      } catch (_) {}
      throw _RateLimitException(errorMsg, retryAfter);
    }

    if (response.statusCode != 200) {
      String errorMsg = 'Groq API error (${response.statusCode})';
      try {
        final errorBody =
            json.decode(response.body) as Map<String, dynamic>;
        final apiError =
            (errorBody['error'] as Map<String, dynamic>?)?['message'];
        if (apiError != null) errorMsg = apiError as String;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final Map<String, dynamic> responseJson =
        json.decode(response.body) as Map<String, dynamic>;
    final choices = responseJson['choices'] as List<dynamic>;
    final generatedText = choices[0]['message']['content'] as String;

    return McqQuestion.parseList(generatedText);
  }

  List<McqQuestion> _parseResponse(String responseBody) {
    final Map<String, dynamic> responseJson =
        json.decode(responseBody) as Map<String, dynamic>;
    final choices = responseJson['choices'] as List<dynamic>;
    final generatedText = choices[0]['message']['content'] as String;
    return McqQuestion.parseList(generatedText);
  }

  /// Tries to read the `retry-after` or `x-ratelimit-reset-tokens` headers.
  int? _parseRetryAfter(http.Response response) {
    final retryAfterHeader = response.headers['retry-after'];
    if (retryAfterHeader != null) {
      return int.tryParse(retryAfterHeader);
    }
    // Groq sometimes sends fractional seconds in x-ratelimit-reset-tokens
    final resetHeader = response.headers['x-ratelimit-reset-tokens'];
    if (resetHeader != null) {
      // Format can be "12.13s" or "12129ms"
      final ms = resetHeader.endsWith('ms')
          ? int.tryParse(resetHeader.replaceAll('ms', ''))
          : null;
      if (ms != null) return (ms / 1000).ceil();
      final s = double.tryParse(resetHeader.replaceAll('s', ''));
      if (s != null) return s.ceil();
    }
    return null;
  }

  List<String> _splitText(String text, int chunkSize) {
    final List<String> chunks = [];
    int start = 0;
    while (start < text.length) {
      int end = start + chunkSize;
      if (end > text.length) end = text.length;

      // Try to break at a newline to keep context together
      if (end < text.length) {
        final lastNewline = text.lastIndexOf('\n', end);
        if (lastNewline > start + (chunkSize * 0.5)) {
          end = lastNewline;
        }
      }

      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }

  // ── Flashcard Generation ───────────────────────────────────────────────────

  Future<List<Flashcard>> generateFlashcards(String text, {String? topic}) async {
    if (text.trim().isEmpty) throw Exception('No text provided.');

    final systemPrompt = 'You are a smart educational flashcard generator. '
        'Generate high-quality flashcards from the text. '
        'Follow the "Minimum Information Principle": each card should cover exactly ONE concept. '
        'Keep the front (question) and back (answer) concise. '
        'IMPORTANT: Output ONLY a JSON object with a "flashcards" key containing an array of objects.\n'
        'Each object must have: "front" and "back" keys.';

    final response = await _processWithPromptAndRetry(text, systemPrompt);
    // Note: _processWithPromptAndRetry currently returns McqQuestions. 
    // I should create a generic version or a specific one for flashcards.
    // I will add a flashcard-specific method below.
    return _generateFlashcardsInternal(text, systemPrompt, topic ?? 'Extracted');
  }

  Future<List<Flashcard>> generateTopicFlashcards(String topic) async {
    final systemPrompt = 'You are a medical education expert. '
        'Generate EXACTLY 15 high-yield flashcards about the topic provided. '
        'Focus on key definitions, clinical signs, and treatments. '
        'IMPORTANT: Output ONLY a JSON object with a "flashcards" key containing an array of objects.\n'
        'Each object must have: "front" and "back" keys.';

    return _generateFlashcardsInternal(topic, systemPrompt, topic);
  }

  Future<List<Flashcard>> _generateFlashcardsInternal(String input, String systemPrompt, String topic) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': input},
            ],
            'temperature': 0.7,
            'max_tokens': 4000,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final content = data['choices'][0]['message']['content'];
          final Map<String, dynamic> parsed = json.decode(content);
          final List<dynamic> cards = parsed['flashcards'] ?? [];

          return cards.map((c) => Flashcard.create(
            front: c['front'] ?? '',
            back: c['back'] ?? '',
            topic: topic,
          )).toList();
        } else if (response.statusCode == 429) {
          await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
          continue;
        }
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return [];
  }
}


/// Internal exception used to signal HTTP 429 with optional retry delay.
class _RateLimitException implements Exception {
  final String message;
  final int? retryAfterSeconds;
  const _RateLimitException(this.message, this.retryAfterSeconds);
}
