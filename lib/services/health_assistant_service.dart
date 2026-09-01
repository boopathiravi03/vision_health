import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthAssistantService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static Future<Map<String, dynamic>> ask({
    required String query,
    String language = 'English',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/health-assistant'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'language': language,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Health assistant failed: ${response.body}',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}
