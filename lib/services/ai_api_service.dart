import 'dart:convert';

import 'package:http/http.dart' as http;

class AIResult {
  final List<String> symptoms;
  final String duration;
  final String severity;
  final List<String> dangerSigns;
  final String notes;

  AIResult({
    required this.symptoms,
    required this.duration,
    required this.severity,
    required this.dangerSigns,
    required this.notes,
  });

  factory AIResult.fromJson(Map<String, dynamic> json) {
    return AIResult(
      symptoms: List<String>.from(
        json['symptoms'] ?? [],
      ),
      duration: json['duration'] ?? 'Not specified',
      severity: json['severity'] ?? 'Not specified',
      dangerSigns: List<String>.from(
        json['danger_signs'] ?? [],
      ),
      notes: json['notes'] ?? '',
    );
  }
}

class AIApiService {
  // Android emulator → computer localhost
  static const String baseUrl =
      'https://vision-health.onrender.com';

  Future<AIResult> analyze({
    required String patientName,
    required int age,
    required String gender,
    required String language,
    required String transcript,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patient_name': patientName,
        'age': age,
        'gender': gender,
        'language': language,
        'transcript': transcript,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI server error: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    return AIResult.fromJson(
      decoded['data'],
    );
  }
}
