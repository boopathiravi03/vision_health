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
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
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
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
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
        Uri.parse('$_baseUrl/vision-analyze'),
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

    final quality =
        result['image_quality_good'] == true;

    final observation =
        result['observation']?.toString() ?? '';

    final indicators =
        result['visible_indicators'];

    final urgency =
        result['urgency']?.toString() ?? 'UNKNOWN';

    final recommendation =
        result['recommendation']?.toString() ?? '';

    final disclaimer =
        result['disclaimer']?.toString() ??
            'This is a screening aid and not a diagnosis.';

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
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF087F73),
              ),

              SizedBox(width: 8),

              Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _resultRow(
            'Image quality',
            quality
                ? 'Good'
                : 'Not suitable for analysis',
          ),

          _resultRow(
            'Urgency',
            urgency,
          ),

          if (observation.isNotEmpty)
            _resultSection(
              'What AI can see',
              observation,
            ),

          if (indicators is List &&
              indicators.isNotEmpty)
            _indicatorList(indicators),

          if (recommendation.isNotEmpty)
            _resultSection(
              'What you should do',
              recommendation,
            ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Text(
              disclaimer,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _resultSection(
    String title,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            text,
            style: const TextStyle(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorList(List indicators) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 10),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Visible indicators',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          ...indicators.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 3,
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text('• '),

                  Expanded(
                    child: Text(
                      item.toString(),
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

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
