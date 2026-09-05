import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthAssistantService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  Future<String> askAssistant({
    required String query,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/health-assistant');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': query.trim(),
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 60));

      print('Health Assistant status: ${response.statusCode}');
      print('Health Assistant body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Health Assistant error ${response.statusCode}: '
          '${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        throw Exception(
          decoded['response']?.toString() ??
              'Health Assistant returned an invalid response.',
        );
      }

      final answer = decoded['response']?.toString().trim();

      if (answer == null || answer.isEmpty) {
        throw Exception('Health Assistant returned an empty response.');
      }

      return answer;
    } catch (e) {
      print('Health Assistant request failed: $e');
      rethrow;
    }
  }
}
