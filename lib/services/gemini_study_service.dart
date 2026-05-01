import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/study_task.dart';

class GeminiStudyService {
  static const String _apiKey = 'AIzaSyBx9R2q92FjJqiSPdgvFVX2QH0Ul9bdd9w';
  
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );



  /// Option C: Overarching strategy banner for AI generated plans
  Future<String> getStrategyForTopic(String topic, int days) async {
    try {
      final prompt = '''
You are an expert medical education study coach.
The user is about to embark on a $days-day study plan to master: "$topic".

Provide a high-level, 2-sentence strategy on the best way to conquer this topic over the next $days days. 
What is the most important concept to nail down first?
Keep it concise, actionable and encouraging. Do not use markdown formatting like bolding.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'Start with the fundamentals, then move to clinical applications!';
    } catch (e) {
       return "Start with the fundamentals, then move to clinical applications! (AI temporarily unavailable)";
    }
  }
}
