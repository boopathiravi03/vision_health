import 'dart:convert';

import 'package:http/http.dart' as http;

class SpeechFormService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static Future<Map<String, dynamic>>
      extractForm(
    String transcript,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/ai/speech-to-form',
      ),
      headers: {
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'transcript': transcript,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI request failed: ${response.body}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    return Map<String, dynamic>.from(
      decoded['data'],
    );
  }
}
