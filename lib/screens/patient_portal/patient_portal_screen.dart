import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import '../../services/patient_service.dart';
import '../schemes/scheme_finder_screen.dart';

class PatientPortalScreen extends StatefulWidget {
  const PatientPortalScreen({super.key});

  @override
  State<PatientPortalScreen> createState() => _PatientPortalScreenState();
}

class _PatientPortalScreenState extends State<PatientPortalScreen> {
  final PatientService _patientService = PatientService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  String _lastTranscript = '';
  String _aiReply = '';
  bool _aiLoading = false;

  String _patientId = '';
  Map<String, dynamic>? _loadedPatient;
  String _patientLoadError = '';

  File? _capturedImage;
  String _visionResult = '';
  bool _visionLoading = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _capturedImage = File(image.path);
        _visionLoading = true;
        _visionResult = '';
      });

      final bytes = await _capturedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://vision-health.onrender.com/vision-analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final explanation = decoded['explanation']?.toString() ??
            decoded['message']?.toString() ??
            'No explanation returned.';

        setState(() {
          _visionResult = explanation;
          _visionLoading = false;
        });
      } else {
        setState(() {
          _visionResult = 'Image analysis failed: ${response.statusCode}';
          _visionLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _visionResult = 'Unable to analyze image: $e';
        _visionLoading = false;
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _aiLoading = true;
      _aiReply = '';
    });

    await _speech.listen(onResult: (result) {
      setState(() {
        _lastTranscript = result.recognizedWords;
      });
    });

    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });

    if (_lastTranscript.trim().isEmpty) {
      setState(() {
        _aiLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://vision-health.onrender.com/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': _lastTranscript}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final reply = decoded['reply']?.toString() ??
            decoded['message']?.toString() ??
            'No reply from Vission AI.';

        setState(() {
          _aiReply = reply;
          _aiLoading = false;
        });

        await _tts.speak(reply);
      } else {
        setState(() {
          _aiReply = 'AI request failed: ${response.statusCode}';
          _aiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiReply = 'Unable to reach Vission AI: $e';
        _aiLoading = false;
      });
    }
  }

  Future<void> _loadPatientById() async {
    if (_patientId.trim().isEmpty) {
      setState(() {
        _patientLoadError = 'Enter a Patient ID first.';
      });
      return;
    }

    setState(() {
      _patientLoadError = '';
      _loadedPatient = null;
    });

    try {
      final data = await _patientService.getPatient(_patientId.trim());

      setState(() {
        _loadedPatient = data;
      });
    } catch (e) {
      setState(() {
        _patientLoadError = 'Unable to load patient: $e';
        _loadedPatient = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Patient Portal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(),

            const SizedBox(height: 24),

            const Text(
              'My Health Tools',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _featureCard(
              context,
              icon: Icons.mic,
              title: 'Talk to Vission AI',
              subtitle: 'Ask a health question by voice and hear the answer.',
              trailing: _isListening
                  ? const Text('Listening...',
                      style: TextStyle(color: Colors.red))
                  : Text(_lastTranscript.isEmpty
                      ? ''
                      : _lastTranscript),
              onTap: _isListening ? _stopListening : _startListening,
            ),

            if (_aiLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(),
              ),

            if (_aiReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E9E6)),
                  ),
                  child: Text(_aiReply),
                ),
              ),

            const SizedBox(height: 10),

            _featureCard(
              context,
              icon: Icons.camera_alt,
              title: 'AI Image Explanation',
              subtitle: _visionLoading
                  ? 'Analyzing image...'
                  : (_visionResult.isEmpty
                      ? 'Take a photo of a medicine package or report.'
                      : _visionResult),
              onTap: _pickImage,
            ),

            const SizedBox(height: 10),

            _featureCard(
              context,
              icon: Icons.badge,
              title: 'My ASHA Health Record',
              subtitle: _loadedPatient == null
                  ? 'Enter your Patient ID to view your health record.'
                  : 'Loaded: ${_loadedPatient!['name'] ?? 'Patient'}',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Enter Patient ID'),
                      content: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Patient ID',
                        ),
                        onChanged: (value) {
                          _patientId = value;
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('CANCEL'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _loadPatientById();
                          },
                          child: const Text('LOAD'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            if (_patientLoadError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _patientLoadError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_loadedPatient != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E9E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_loadedPatient!['name'] ?? '-'}'),
                      Text('Age: ${_loadedPatient!['age'] ?? '-'}'),
                      Text('Gender: ${_loadedPatient!['gender'] ?? '-'}'),
                      Text('Village: ${_loadedPatient!['village'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'Symptoms: ${_loadedPatient!['symptoms'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            _featureCard(
              context,
              icon: Icons.account_balance,
              title: 'Government Benefits',
              subtitle: 'Check health schemes using your health record.',
              onTap: () {
                final age = int.tryParse(_loadedPatient!['age']?.toString() ?? '') ?? 0;
                final gender = _loadedPatient!['gender']?.toString() ?? '';
                final symptoms = _loadedPatient!['symptoms']?.toString() ?? '';

                if (_loadedPatient == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Load your health record first.'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchemeFinderScreen(
                      age: age,
                      gender: gender,
                      situation: symptoms,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 34,
              color: Color(0xFF087F73),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Vission Health',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Access your health information in one place.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9E6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF087F73)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, height: 1.3),
          ),
        ),
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
