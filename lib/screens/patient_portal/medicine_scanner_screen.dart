import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MedicineScannerScreen extends StatefulWidget {
  const MedicineScannerScreen({super.key});

  @override
  State<MedicineScannerScreen> createState() =>
      _MedicineScannerScreenState();
}

class _MedicineScannerScreenState
    extends State<MedicineScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _scanMedicine() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _image = File(image.path);
      _result = null;
      _loading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://vision-health.onrender.com/vision-analyze',
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
        ),
      );

      final streamed = await request.send();
      final response =
          await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      setState(() {
        _result = decoded;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to analyse image: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text('Scan Medicine'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _header(),

            const SizedBox(height: 20),

            _imagePreview(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed:
                    _loading ? null : _scanMedicine,
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
                    : const Icon(Icons.camera_alt),

                label: Text(
                  _loading
                      ? 'ANALYSING...'
                      : 'SCAN MEDICINE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 25),
              _resultCard(),
            ],

            const SizedBox(height: 20),

            _safetyNotice(),
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
          Icon(
            Icons.medication_outlined,
            size: 48,
            color: Color(0xFF087F73),
          ),

          SizedBox(height: 10),

          Text(
            'Forgot what this medicine is?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073B36),
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Take a clear photo of the medicine strip '
            'or package. AI will explain the visible '
            'information in simple language.',
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

  Widget _imagePreview() {
    return Container(
      width: double.infinity,
      height: 230,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),

      child: _image == null
          ? const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  'Medicine photo will appear here',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: Image.file(
                _image!,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Widget _resultCard() {
    final result = _result ?? {};

    final observation =
        result['observation']?.toString() ??
            'No clear information detected.';

    final indicators =
        result['visible_indicators'];

    final recommendation =
        result['recommendation']?.toString() ??
            'Please verify the medicine with a healthcare professional.';

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
                'AI Result',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'What I can see',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            observation,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          if (indicators is List &&
              indicators.isNotEmpty) ...[
            const Text(
              'Visible information',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            ...indicators.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 6,
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

            const SizedBox(height: 12),
          ],

          const Text(
            'Next step',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyNotice() {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
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
              'AI image analysis is only a screening '
              'aid. Do not change, stop or start a '
              'medicine based only on this result. '
              'Confirm the medicine with an ASHA worker, '
              'doctor or pharmacist.',
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
