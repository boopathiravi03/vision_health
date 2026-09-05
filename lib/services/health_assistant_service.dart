import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthAssistantService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static const Duration requestTimeout =
      Duration(seconds: 60);

  Future<String> askAssistant({
    required String query,
    required String language,
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      throw Exception(
        'Please enter a question.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/health-assistant',
    );

    try {
      print('----------------------------------------');
      print('VISSION HEALTH ASSISTANT');
      print('URL: $uri');
      print('QUERY: $cleanQuery');
      print('LANGUAGE: $language');
      print('----------------------------------------');

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
          .timeout(requestTimeout);

      print(
        'Health Assistant HTTP status: '
        '${response.statusCode}',
      );

      print(
        'Health Assistant response: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String serverMessage =
            'Health Assistant server error '
            '(${response.statusCode}).';

        try {
          final errorData =
              jsonDecode(response.body);

          if (errorData is Map) {
            final error = errorData['error'];

            if (error is Map &&
                error['message'] != null) {
              serverMessage =
                  error['message'].toString();
            } else if (errorData['detail'] != null) {
              serverMessage =
                  errorData['detail'].toString();
            } else if (errorData['message'] != null) {
              serverMessage =
                  errorData['message'].toString();
            }
          }
        } catch (_) {
          // Response was not JSON.
        }

        throw Exception(serverMessage);
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'The health assistant returned invalid JSON.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'The health assistant returned an invalid response.',
        );
      }

      String? answer;

      if (decoded['response'] != null) {
        answer = decoded['response'].toString();
      }

      if ((answer == null || answer.trim().isEmpty) &&
          decoded['answer'] != null) {
        answer = decoded['answer'].toString();
      }

      if ((answer == null || answer.trim().isEmpty) &&
          decoded['message'] != null) {
        answer = decoded['message'].toString();
      }

      final data = decoded['data'];

      if ((answer == null || answer.trim().isEmpty) &&
          data is Map) {
        if (data['response'] != null) {
          answer = data['response'].toString();
        } else if (data['answer'] != null) {
          answer = data['answer'].toString();
        } else if (data['message'] != null) {
          answer = data['message'].toString();
        }
      }

      if (answer == null || answer.trim().isEmpty) {
        final backendError =
            decoded['error'] ??
            decoded['detail'];

        if (backendError != null) {
          if (backendError is Map &&
              backendError['message'] != null) {
            throw Exception(
              backendError['message'].toString(),
            );
          }

          throw Exception(
            backendError.toString(),
          );
        }

        throw Exception(
          'Health assistant returned an empty response.',
        );
      }

      answer = answer.trim();

      print(
        'Health Assistant answer: $answer',
      );

      print('----------------------------------------');

      return answer;
    }

    on http.ClientException catch (e) {
      print(
        'Health Assistant connection error: $e',
      );

      throw Exception(
        'Could not connect to Vission AI. '
        'Please check your internet connection '
        'and try again.',
      );
    }

    on Exception catch (e) {
      print(
        'Health Assistant exception: $e',
      );

      rethrow;
    }

    catch (e) {
      print(
        'Health Assistant unknown error: $e',
      );

      throw Exception(
        'Something went wrong while contacting '
        'Vission AI.',
      );
    }
  }
}
