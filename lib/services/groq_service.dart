import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcq.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt =
      'You are a smart educational quiz generator. '
      'Generate multiple choice questions strictly based on the provided text. '
      'IMPORTANT: You must output ONLY a valid JSON object with a single key "questions" containing an array of objects.\n'
      'Each object must have exactly these keys:\n'
      '  "question": the question string\n'
      '  "options": array of exactly 4 strings, each prefixed with "A. ", "B. ", "C. ", "D. "\n'
      '  "answer": must exactly match one of the options strings\n'
      'The provided text contains many MCQs. You must extract and format EVERY SINGLE QUESTION found in the text. Do not stop early. Extract all of them.\n';

  // Groq API Key
  static const String _apiKey = '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';

  GroqService();

  Future<List<McqQuestion>> generateMcqs(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('No text provided for quiz generation.');
    }
    if (_apiKey.trim().isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception('Groq API key is not configured in the code.');
    }

    // Chunk the text to stay within limits and avoid truncation
    final List<String> chunks = _splitText(text, 4000);
    final List<McqQuestion> allQuestions = [];

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final questions = await _processChunk(chunk);
      allQuestions.addAll(questions);
      
      // Optional: Add a small delay between chunks to be kinder to rate limits
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (allQuestions.isEmpty) {
      throw Exception(
        'Could not parse quiz questions from the AI response.\n'
        'Try providing more detailed or longer text.',
      );
    }

    return allQuestions;
  }

  Future<List<McqQuestion>> _processChunk(String chunk) async {
    final uri = Uri.parse(_baseUrl);

    final requestBody = json.encode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': 'Text to extract quizzes from:\n$chunk'}
      ],
      'temperature': 0.1,
      'max_tokens': 4096,
      'response_format': {'type': 'json_object'},
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: requestBody,
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      String errorMsg = 'Groq API error (${response.statusCode})';
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final apiError = (errorBody['error'] as Map<String, dynamic>?)?['message'];
        if (apiError != null) errorMsg = apiError as String;
      } catch (_) {}
      
      // If it's a rate limit error, provide a clearer message
      if (response.statusCode == 429) {
        throw Exception('Rate limit reached. Please wait a moment or try a smaller section of text.\nDetails: $errorMsg');
      }
      throw Exception(errorMsg);
    }

    final Map<String, dynamic> responseJson = json.decode(response.body) as Map<String, dynamic>;
    final choices = responseJson['choices'] as List<dynamic>;
    final generatedText = choices[0]['message']['content'] as String;

    return McqQuestion.parseList(generatedText);
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
}
