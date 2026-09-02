import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  Future<Map<String, dynamic>> extractPatientData(
    String transcript,
  ) async {
    if (transcript.trim().isEmpty) {
      throw Exception('Transcript is empty.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/ai/speech-to-form'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'transcript': transcript,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI extraction failed: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('AI returned invalid patient data.');
    }

    return Map<String, dynamic>.from(data);
  }
}
