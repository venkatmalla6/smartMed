import 'dart:convert';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyBx9R2q92FjJqiSPdgvFVX2QH0Ul9bdd9w';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = json.decode(responseBody);
    final models = data['models'] as List;
    for (var m in models) {
      if (m['supportedGenerationMethods'].contains('generateContent')) {
        print(m['name']);
      }
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
