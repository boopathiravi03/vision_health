import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://mississippi-delivering-functions-taxes.trycloudflare.com';

  static Future<Map<String, dynamic>>
      getTriageExplanation({
    required String patientName,
    required int age,
    required List<String> symptoms,
    required String riskLevel,
    required String action,
    required String language,
  }) async {
    final url = Uri.parse(
      '$baseUrl/triage/explanation',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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

    if (response.statusCode == 200) {
      return jsonDecode(
        response.body,
      ) as Map<String, dynamic>;
    }

    throw Exception(
      'Triage API failed: ${response.statusCode} ${response.body}',
    );
  }
}
