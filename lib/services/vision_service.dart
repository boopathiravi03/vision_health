import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/vision_result.dart';

class VisionService {
  static const String baseUrl =
      'https://vision-health.onrender.com';

  Future<VisionResult> analyzeImage(
    File image,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vision-analyze'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Vision server error: ${response.body}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    return VisionResult.fromJson(
      decoded['data'],
    );
  }
}
