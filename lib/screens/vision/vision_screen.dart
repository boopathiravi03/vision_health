import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/vision_result.dart';
import '../../services/vision_service.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({
    super.key,
  });

  @override
  State<VisionScreen> createState() =>
      _VisionScreenState();
}

class _VisionScreenState
    extends State<VisionScreen> {
  final ImagePicker _picker =
      ImagePicker();

  final VisionService _visionService =
      VisionService();

  File? selectedImage;

  VisionResult? result;

  bool loading = false;

  Future<void> captureImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
      result = null;
    });
  }

  Future<void> analyzeImage() async {
    if (selectedImage == null) return;

    setState(() {
      loading = true;
    });

    try {
      final response =
          await _visionService.analyzeImage(
        selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        result = response;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to analyze image. Check your connection.',
          ),
        ),
      );
    }
  }

  Color urgencyColor(String urgency) {
    switch (urgency) {
      case 'URGENT':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visual Screening',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Capture Image',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Take a clear image for AI-assisted visual screening.',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: selectedImage == null
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 70,
                        color: Colors.grey,
                      ),
                    )
                  : Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                    ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: captureImage,
              icon: const Icon(
                Icons.camera_alt_rounded,
              ),
              label: const Text(
                'CAPTURE IMAGE',
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed:
                  selectedImage == null ||
                          loading
                      ? null
                      : analyzeImage,
              icon: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
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
                loading
                    ? 'ANALYZING...'
                    : 'ANALYZE WITH AI',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF087F73),
                minimumSize:
                    const Size.fromHeight(52),
              ),
            ),

            if (result != null) ...[
              const SizedBox(height: 28),
              _buildResult(result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
    VisionResult result,
  ) {
    final color =
        urgencyColor(result.urgency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3EAE8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: Color(0xFF087F73),
              ),
              const SizedBox(width: 10),
              Text(
                'Screening Result',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: Text(
              result.urgency,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Observation',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            result.observation,
            style: const TextStyle(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          if (result.visibleIndicators
              .isNotEmpty) ...[
            Text(
              'Visible Indicators',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            ...result.visibleIndicators.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 17,
                      color:
                          Color(0xFF087F73),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(item),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          Text(
            'Recommended Action',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            result.recommendation,
            style: const TextStyle(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              result.disclaimer,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
