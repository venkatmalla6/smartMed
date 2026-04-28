import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Reusing the same API key from GroqService
  static const String _apiKey = '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';

  static const String _systemPrompt = 
      'You are a professional translator specializing in medical and educational content. '
      'Your task is to translate text from Russian or Kazakh to English. '
      'Maintain the professional tone, preserve medical terminology accurately, and ensure the translation is natural in English. '
      'If the input contains Kazakh, pay special attention to cultural nuances and specific terminology. '
      'Provide ONLY the translated text without any explanations or additional comments.';

  Future<String> translate(String text, {String sourceLanguage = 'auto'}) async {
    if (text.trim().isEmpty) return '';

    final uri = Uri.parse(_baseUrl);
    
    String languageHint = '';
    if (sourceLanguage == 'ru') {
      languageHint = 'The source language is Russian.';
    } else if (sourceLanguage == 'kk') {
      languageHint = 'The source language is Kazakh.';
    } else {
      languageHint = 'Auto-detect the source language (either Russian or Kazakh).';
    }

    final requestBody = json.encode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': '$languageHint\n\nText to translate:\n$text'}
      ],
      'temperature': 0.3,
      'max_tokens': 4096,
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Translation failed: ${response.statusCode}');
      }

      final Map<String, dynamic> responseJson = json.decode(response.body);
      final choices = responseJson['choices'] as List<dynamic>;
      return (choices[0]['message']['content'] as String).trim();
    } catch (e) {
      throw Exception('Error during translation: $e');
    }
  }
}
