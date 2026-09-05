import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthAssistantService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static const Duration timeoutDuration =
      Duration(seconds: 90);

  Future<String> askAssistant({
    required String query,
    required String language,
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      throw Exception('Please enter a health question.');
    }

    final uri = Uri.parse('$baseUrl/health-assistant');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': cleanQuery,
              'language': language,
            }),
          )
          .timeout(timeoutDuration);

      print('====================================');
      print('VISSION HEALTH ASSISTANT');
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');
      print('====================================');

      if (response.statusCode != 200) {
        String message;

        try {
          final errorBody = jsonDecode(response.body);

          message =
              errorBody['detail']?.toString() ??
              errorBody['error']?.toString() ??
              'Health Assistant server error.';
        } catch (_) {
          message = response.body.isNotEmpty
              ? response.body
              : 'Health Assistant server error.';
        }

        throw Exception(
          'Health Assistant error '
          '${response.statusCode}: $message',
        );
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'The server returned invalid JSON.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Invalid Health Assistant response.',
        );
      }

      final success = decoded['success'];

      if (success != true) {
        throw Exception(
          decoded['detail']?.toString() ??
          decoded['error']?.toString() ??
          decoded['response']?.toString() ??
          'Health Assistant request failed.',
        );
      }

      final answer =
          decoded['response']?.toString().trim();

      if (answer == null || answer.isEmpty) {
        throw Exception(
          'Health Assistant returned an empty response.',
        );
      }

      return answer;
    } on TimeoutException {
      throw Exception(
        'Vission AI is taking too long to respond. '
        'Please try again.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Unable to connect to Vission AI: $e',
      );
    } catch (e) {
      print('Health Assistant FAILED: $e');
      rethrow;
    }
  }
}
