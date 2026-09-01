import 'dart:convert';
import 'package:http/http.dart' as http;

class SchemeService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static Future<Map<String, dynamic>> findSchemes({
    required int age,
    required String gender,
    required String situation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scheme-finder'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'age': age,
        'gender': gender,
        'situation': situation,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Scheme request failed: ${response.body}',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}
