import 'dart:convert';

import 'package:http/http.dart' as http;

class TriageAiService {
  static const String baseUrl =
      'https://mississippi-delivering-functions-taxes.trycloudflare.com';

  static Future<String> getExplanation({
    required String patientName,
    required int age,
    required List<String> symptoms,
    required String riskLevel,
    required String action,
    String language = 'English',
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/triage/explanation',
      ),
      headers: {
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'patient_name': patientName,
        'age': age,
        'symptoms': symptoms,
        'risk_level': riskLevel,
        'action': action,
        'language': language,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI server error: ${response.statusCode}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(
        'AI explanation failed',
      );
    }

    return data['explanation']
            ?.toString() ??
        'No explanation available.';
  }
}
