import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl =
      'https://mississippi-delivering-functions-taxes.trycloudflare.com';

  Future<String> analyzeHealthQuery(
    String query, {
    required String language,
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
        'AI server error: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return data['response'] ?? 'No response received.';
  }
}
