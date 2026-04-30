import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _apiKey =
      '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';

  // Same model as original
  static const String _model = 'llama-3.3-70b-versatile';

  static const int _maxRetries = 4;

  static const String _systemPrompt =
      'You are a professional translator specializing in medical and educational content. '
      'Your task is to translate text from Russian or Kazakh to English. '
      'Maintain the professional tone, preserve medical terminology accurately, and ensure the translation is natural in English. '
      'If the input contains Kazakh, pay special attention to cultural nuances and specific terminology. '
      'Provide ONLY the translated text without any explanations or additional comments.';

  Future<String> translate(
    String text, {
    String sourceLanguage = 'auto',
  }) async {
    if (text.trim().isEmpty) return '';

    String languageHint = '';
    if (sourceLanguage == 'ru') {
      languageHint = 'The source language is Russian.';
    } else if (sourceLanguage == 'kk') {
      languageHint = 'The source language is Kazakh.';
    } else {
      languageHint =
          'Auto-detect the source language (either Russian or Kazakh).';
    }

    return _translateWithRetry(text, languageHint);
  }

  Future<String> _translateWithRetry(
    String text,
    String languageHint,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        return await _doTranslate(text, languageHint);
      } on _RateLimitException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw Exception(
            'Rate limit exceeded after $_maxRetries attempts. '
            'Please wait a minute and try again.',
          );
        }
        final waitSeconds =
            e.retryAfterSeconds ?? min(60, pow(2, attempt).toInt());
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }
  }

  Future<String> _doTranslate(String text, String languageHint) async {
    final uri = Uri.parse(_baseUrl);

    final requestBody = json.encode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': '$languageHint\n\nText to translate:\n$text',
        },
      ],
      'temperature': 0.3,
      'max_tokens': 4096,
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
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 429) {
      final retryAfter = _parseRetryAfter(response);
      String errorMsg = 'Rate limit reached during translation.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final msg = (body['error'] as Map<String, dynamic>?)?['message'];
        if (msg != null) errorMsg = msg as String;
      } catch (_) {}
      throw _RateLimitException(errorMsg, retryAfter);
    }

    if (response.statusCode != 200) {
      throw Exception('Translation failed: ${response.statusCode}');
    }

    final Map<String, dynamic> responseJson = json.decode(response.body);
    final choices = responseJson['choices'] as List<dynamic>;
    return (choices[0]['message']['content'] as String).trim();
  }

  int? _parseRetryAfter(http.Response response) {
    final retryAfterHeader = response.headers['retry-after'];
    if (retryAfterHeader != null) {
      return int.tryParse(retryAfterHeader);
    }
    final resetHeader = response.headers['x-ratelimit-reset-tokens'];
    if (resetHeader != null) {
      final ms = resetHeader.endsWith('ms')
          ? int.tryParse(resetHeader.replaceAll('ms', ''))
          : null;
      if (ms != null) return (ms / 1000).ceil();
      final s = double.tryParse(resetHeader.replaceAll('s', ''));
      if (s != null) return s.ceil();
    }
    return null;
  }
}

class _RateLimitException implements Exception {
  final String message;
  final int? retryAfterSeconds;
  const _RateLimitException(this.message, this.retryAfterSeconds);
}
