import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  print('Available scripts:');
  for (var value in TextRecognitionScript.values) {
    print(value);
  }
}
