import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, dynamic>> extractPatientData(
    String transcript,
  ) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content': '''
You are a healthcare data extraction assistant
for Vission Health.

The input may be in English, Tamil, Hindi,
or another Indian language.

Extract patient information from the ASHA
worker's spoken note.

Translate the meaning internally if necessary,
but return the structured fields in English.

Return ONLY valid JSON.

Required fields:
name
age
gender
village
phone
symptoms

Rules:
1. Never invent missing information.
2. If a field is not mentioned, return "".
3. Preserve the patient's actual information.
4. Translate symptoms into concise English.
5. Do not diagnose the patient.
6. Do not recommend medicines.
7. Do not create medical facts that were not spoken.

Example input:
"மீனா வயது 28. காய்ச்சல் மற்றும் உடல்
சோர்வு இரண்டு நாட்களாக இருக்கிறது."

Example output:
{
  "name": "Meena",
  "age": "28",
  "gender": "",
  "village": "",
  "phone": "",
  "symptoms": "Fever and weakness for two days"
}
''',
          },
          {
            'role': 'user',
            'content': transcript,
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq API error: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    final content =
        data['choices'][0]['message']['content'];

    return jsonDecode(
      _cleanJson(content),
    );
  }

  String _cleanJson(String text) {
    text = text.trim();

    if (text.startsWith('```json')) {
      text = text
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (text.startsWith('```')) {
      text = text
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    return text;
  }
}
