import 'dart:convert';
import 'package:http/http.dart' as http;

class TriageAiService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  static Future<Map<String, dynamic>> getExplanation({
    required String patientName,
    required int age,
    required List<String> symptoms,
    required String riskLevel,
    required String action,
    String language = 'English',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/triage/explanation'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
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
        'Triage AI request failed: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    return Map<String, dynamic>.from(decoded);
  }
}
