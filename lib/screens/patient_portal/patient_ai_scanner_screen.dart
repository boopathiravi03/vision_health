import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PatientAiScannerScreen extends StatefulWidget {
  const PatientAiScannerScreen({
    super.key,
  });

  @override
  State<PatientAiScannerScreen> createState() =>
      _PatientAiScannerScreenState();
}

class _PatientAiScannerScreenState
    extends State<PatientAiScannerScreen> {
  static const String _baseUrl =
      'https://vision-health.onrender.com';

  final ImagePicker _picker = ImagePicker();

  File? _image;

  bool _loading = false;

  Map<String, dynamic>? _result;

  String? _error;

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;

      setState(() {
        _image = File(image.path);
        _result = null;
        _error = null;
      });
    } catch (e) {
      _showError('Could not open camera.');
    }
  }

  Future<void> _choosePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;

      setState(() {
        _image = File(image.path);
        _result = null;
        _error = null;
      });
    } catch (e) {
      _showError('Could not open gallery.');
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null || _loading) return;

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final file = _image!;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/medicine-analyze'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 75),
        onTimeout: () {
          throw TimeoutException(
            'The AI service took too long to respond.',
          );
        },
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      Map<String, dynamic>? decoded;

      try {
        final body = jsonDecode(response.body);

        if (body is Map<String, dynamic>) {
          decoded = body;
        }
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200) {
        String message =
            'Vision service error (${response.statusCode}).';

        if (decoded != null) {
          final detail = decoded['detail'];

          if (detail != null &&
              detail.toString().trim().isNotEmpty) {
            message = detail.toString();
          }
        }

        throw Exception(message);
      }

      if (decoded == null ||
          decoded['data'] is! Map) {
        throw Exception(
          'The vision service returned an invalid result.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        decoded['data'] as Map,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _error =
            'The AI service took too long to respond. '
            'Please try again with a clear, smaller image.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'AI Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            _header(),

            const SizedBox(height: 20),

            _imageCard(),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _loading ? null : _takePhoto,
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                    ),
                    label: const Text('CAMERA'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _loading ? null : _choosePhoto,
                    icon: const Icon(
                      Icons.photo_library_rounded,
                    ),
                    label: const Text('GALLERY'),
                  ),
                ),
              ],
            ),

            if (_image != null) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _analyzeImage,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                        ),
                  label: Text(
                    _loading
                        ? 'ANALYZING...'
                        : 'ANALYZE WITH AI',
                  ),
                ),
              ),
            ],

            if (_loading) ...[
              const SizedBox(height: 12),

              const Text(
                'AI is reading the visible information. '
                'This may take up to a minute.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 18),
              _errorCard(),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              _resultCard(),
            ],

            const SizedBox(height: 24),

            _warningCard(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.document_scanner_rounded,
              size: 38,
              color: Color(0xFF087F73),
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Scan & Understand',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073B36),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Take a clear photo of a medicine package, '
            'prescription or health report. '
            'Vission AI will explain visible information '
            'in simple language.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard() {
    return Container(
      width: double.infinity,
      height: 250,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: _image == null
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 52,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No image selected',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Image.file(
              _image!,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
              ),

              SizedBox(width: 8),

              Text(
                'Analysis failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _error!,
            style: const TextStyle(
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed:
                _loading ? null : _analyzeImage,
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final result = _result!;

    final quality = result['image_quality_good'] == true;

    final medicineName =
        _value(result['medicine_name'], 'Not clearly identified');

    final strength =
        _value(result['strength'], 'Not visible');

    final medicineType =
        _value(result['medicine_type'], 'Medicine');

    final whatItIs = _value(
      result['what_it_is'] ??
          result['what_it_appears_to_be'],
      medicineName == 'Not clearly identified'
          ? 'Not available'
          : medicineName,
    );

    final usedFor = _value(
      result['what_it_is_used_for'] ??
          result['what_it_appears_to_be_for'],
      'General use information is not available.',
    );

    final whenToTake = _value(
      result['when_to_take'] ??
          result['instructions_visible'],
      'Not shown on the package; follow the prescription or package label.',
    );

    final howToTake = _value(
      result['how_to_take'],
      'Follow the prescription or package label.',
    );

    final explanation =
        _value(result['simple_explanation'], '');

    final confidence =
        _value(result['confidence'], 'LOW');

    final visibleText =
        _value(result['visible_text'], '');

    final sideEffects =
        _stringList(result['common_side_effects']);

    final warnings =
        _stringList(result['warnings']);

    final aiWarning = _value(
      result['warning'],
      'Verify the medicine with a doctor, pharmacist or ASHA worker.',
    );

    final needsVerification =
        result['needs_verification'] != false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medication_rounded,
                color: Color(0xFF087F73),
              ),
              SizedBox(width: 8),
              Text(
                'Medicine Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF073B36),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$strength • $medicineType',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          if (explanation.isNotEmpty)
            _infoSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Simple explanation',
              text: explanation,
            ),

          _infoSection(
            icon: Icons.info_outline_rounded,
            title: 'What is this medicine?',
            text: whatItIs,
          ),

          _infoSection(
            icon: Icons.medical_services_outlined,
            title: 'What is it used for?',
            text: usedFor,
          ),

          _infoSection(
            icon: Icons.schedule_rounded,
            title: 'When to take',
            text: whenToTake,
          ),

          _infoSection(
            icon: Icons.restaurant_outlined,
            title: 'How to take',
            text: howToTake,
          ),

          if (visibleText.isNotEmpty)
            _infoSection(
              icon: Icons.visibility_outlined,
              title: 'Text visible on package',
              text: visibleText,
            ),

          if (sideEffects.isNotEmpty)
            _bulletSection(
              icon: Icons.warning_amber_rounded,
              title: 'Common side effects',
              items: sideEffects,
            ),

          if (warnings.isNotEmpty)
            _bulletSection(
              icon: Icons.health_and_safety_outlined,
              title: 'Important warnings',
              items: warnings,
            ),

          const SizedBox(height: 12),

          _resultRow(
            'AI confidence',
            confidence,
          ),

          _resultRow(
            'Image quality',
            quality ? 'Good' : 'Needs a clearer image',
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    needsVerification
                        ? aiWarning
                        : 'Always follow the prescription or package label.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 23,
            color: const Color(0xFF087F73),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF087F73),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _value(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget _resultRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _warningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.amber.shade200,
        ),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'AI can only describe visible information. '
              'It cannot confirm a diagnosis or safely '
              'identify a medicine from an unclear image. '
              'Always verify important information with '
              'a healthcare professional.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
