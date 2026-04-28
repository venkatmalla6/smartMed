import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/study_task.dart';

class StudyPlanService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKey = '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';

  static const String _systemPrompt =
      'You are a medical education study planner. '
      'Given a topic and number of days, generate a structured daily study plan. '
      'IMPORTANT: Respond ONLY with a valid JSON object with a key "tasks" containing an array. '
      'Each task object must have exactly these keys:\n'
      '  "title": short task title (max 60 chars)\n'
      '  "description": 1–2 sentence description of what to study\n'
      '  "day_offset": integer day offset from today (0 = today, 1 = tomorrow, etc.)\n'
      '  "hour": integer hour of day (8–22) when study session should start\n'
      '  "duration_minutes": integer estimated duration in minutes\n'
      'Create practical, specific, bite-sized study sessions. '
      'Space sessions sensibly throughout each day. '
      'Return between 3 and 15 tasks total.';

  Future<List<StudyTaskSuggestion>> generateStudyPlan({
    required String topic,
    int days = 7,
  }) async {
    if (topic.trim().isEmpty) throw Exception('Please enter a study topic.');

    final uri = Uri.parse(_baseUrl);
    final requestBody = json.encode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': 'Create a $days-day study plan for: "$topic"',
        },
      ],
      'temperature': 0.5,
      'max_tokens': 2048,
      'response_format': {'type': 'json_object'},
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: requestBody,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('AI service error: ${response.statusCode}');
    }

    final responseJson = json.decode(response.body) as Map<String, dynamic>;
    final choices = responseJson['choices'] as List<dynamic>;
    final content = choices[0]['message']['content'] as String;

    final parsed = json.decode(content) as Map<String, dynamic>;
    final tasksList = parsed['tasks'] as List<dynamic>;

    return tasksList
        .whereType<Map<String, dynamic>>()
        .map(StudyTaskSuggestion.fromJson)
        .toList();
  }
}

class StudyTaskSuggestion {
  final String title;
  final String description;
  final int dayOffset;
  final int hour;
  final int durationMinutes;

  StudyTaskSuggestion({
    required this.title,
    required this.description,
    required this.dayOffset,
    required this.hour,
    required this.durationMinutes,
  });

  factory StudyTaskSuggestion.fromJson(Map<String, dynamic> json) {
    return StudyTaskSuggestion(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      dayOffset: (json['day_offset'] as num?)?.toInt() ?? 0,
      hour: (json['hour'] as num?)?.toInt() ?? 9,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
    );
  }

  StudyTask toStudyTask() {
    final now = DateTime.now();
    final scheduled = DateTime(
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      0,
    );
    return StudyTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      scheduledTime: scheduled,
    );
  }
}
