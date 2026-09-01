import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt;

import '../../models/patient.dart';
import '../../services/alert_service.dart';
import '../../services/groq_service.dart';
import '../../services/patient_service.dart';
import '../../services/risk_service.dart';
import '../patient/health_passport_screen.dart';
import '../schemes/scheme_finder_screen.dart';

class VoiceToFormScreen extends StatefulWidget {
  const VoiceToFormScreen({
    super.key,
  });

  @override
  State<VoiceToFormScreen> createState() =>
      _VoiceToFormScreenState();
}

class _VoiceToFormScreenState
    extends State<VoiceToFormScreen> {
  final stt.SpeechToText _speech =
      stt.SpeechToText();

  final GroqService _groq = GroqService();

  final PatientService _patientService =
      PatientService();

  final RiskService _riskService =
      RiskService();

  final AlertService _alertService =
      AlertService();

  bool _isListening = false;
  bool _isProcessing = false;

  String _transcript = '';

  Map<String, dynamic>? _patientData;

  String _selectedLanguage = 'en-IN';

  final Map<String, String> _languages = {
    'en-IN': 'English',
    'ta-IN': 'தமிழ்',
    'hi-IN': 'हिन्दी',
  };

  Future<void> _startListening() async {
    final available =
        await _speech.initialize();

    if (!available) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isListening = true;
      _transcript = '';
      _patientData = null;
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _selectedLanguage,
      ),
      onResult: (result) {
        setState(() {
          _transcript =
              result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processWithAI() async {
    if (_transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please record a patient note first',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await _groq.extractPatientData(
        _transcript,
      );

      setState(() {
        _patientData = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'AI processing failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _savePatient() async {
    if (_patientData == null) return;

    final data = _patientData!;

    final name =
        data['name']?.toString().trim() ?? '';

    final ageText =
        data['age']?.toString().trim() ?? '';

    final gender =
        data['gender']?.toString().trim() ?? '';

    final village =
        data['village']?.toString().trim() ?? '';

    final phone =
        data['phone']?.toString().trim() ?? '';

    final symptoms =
        data['symptoms']?.toString().trim() ?? '';

    final age = int.tryParse(ageText) ?? 0;

    if (name.isEmpty || age <= 0 || symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Name, age and symptoms are required.',
          ),
        ),
      );

      return;
    }

    final risk = _riskService.assess(
      age: age,
      gender: gender,
      symptoms: symptoms,
    );

    final now = DateTime.now();

    DateTime followUp;

    if (risk.level == 'Urgent') {
      followUp = now;
    } else if (risk.level == 'Follow-up') {
      followUp = now.add(
        const Duration(days: 1),
      );
    } else {
      followUp = now.add(
        const Duration(days: 7),
      );
    }

    final followUpDate =
        DateFormat('yyyy-MM-dd').format(
      followUp,
    );

    final patient = Patient(
      id: '',
      name: name,
      age: age,
      gender: gender,
      village: village,
      phone: phone,
      symptoms: symptoms,
      status: 'Pending',
      followUpDate: followUpDate,
      riskLevel: risk.level,
      aiRecommendation:
          risk.recommendation,
    );

    try {
      final patientId =
          await _patientService.addPatient(
        patient,
      );

      if (risk.level == 'Urgent') {
        await _alertService.createAlert(
          patientId: patientId,
          patientName: name,
          riskLevel: risk.level,
          symptoms: symptoms,
          recommendation:
              risk.recommendation,
          village: village,
        );
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF087F73),
                ),
                SizedBox(width: 8),
                Text('Patient Saved'),
              ],
            ),
            content: Text(
              '$name has been added successfully.\n\n'
              'Risk: ${risk.level}\n'
              'Follow-up: $followUpDate',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('DONE'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
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
                icon: const Icon(
                  Icons.account_balance,
                ),
                label: const Text(
                  'VIEW BENEFITS',
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HealthPassportScreen(
                        patientId: patientId,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.qr_code_2,
                ),
                label: const Text(
                  'HEALTH PASSPORT',
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save patient: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: const Text(
          'Speech-to-Form',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _introCard(),

            const SizedBox(height: 24),

            const Text(
              'Patient Voice Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

             const SizedBox(height: 12),

             _languageSelector(),

             const SizedBox(height: 12),

             _recordButton(),

            const SizedBox(height: 20),

            _transcriptCard(),

            if (_transcript.isNotEmpty)
              const SizedBox(height: 16),

            if (_transcript.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _isProcessing
                          ? null
                          : _processWithAI,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                        ),
                  label: Text(
                    _isProcessing
                        ? 'AI PROCESSING...'
                        : 'EXTRACT PATIENT DATA',
                  ),
                ),
              ),

            if (_patientData != null) ...[
              const SizedBox(height: 28),
              _patientPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            const Color(0xFFE8F6F3),
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mic,
            color: Color(0xFF087F73),
            size: 32,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Speak naturally',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tell Vission Health the patient details. AI will convert the voice note into a structured health record.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordButton() {
    return Center(
      child: GestureDetector(
        onTap: _isListening
            ? _stopListening
            : _startListening,

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 250),

          width: 110,
          height: 110,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: _isListening
                ? Colors.red
                : const Color(0xFF087F73),

            boxShadow: [
              BoxShadow(
                blurRadius:
                    _isListening ? 25 : 12,
                spreadRadius:
                    _isListening ? 6 : 2,
                color: (_isListening
                        ? Colors.red
                        : const Color(
                            0xFF087F73,
                          ))
                    .withValues(alpha: 0.20),
              ),
            ],
          ),

          child: Icon(
            _isListening
                ? Icons.stop
                : Icons.mic,
            color: Colors.white,
            size: 46,
          ),
        ),
      ),
    );
  }

  Widget _languageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
          ),
          items: _languages.entries.map(
            (entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      color: Color(0xFF087F73),
                    ),
                    const SizedBox(width: 10),
                    Text(entry.value),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedLanguage = value;
            });
          },
        ),
      ),
    );
  }

  Widget _transcriptCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Transcript',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _transcript.isEmpty
                ? 'Your spoken note will appear here...'
                : _transcript,
            style: TextStyle(
              color: _transcript.isEmpty
                  ? Colors.grey
                  : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientPreview() {
    final data = _patientData!;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFF087F73),
          width: 1.5,
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
                color:
                    Color(0xFF087F73),
              ),
              SizedBox(width: 8),
              Text(
                'AI Extracted Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _field(
            'Name',
            data['name'],
          ),

          _field(
            'Age',
            data['age'],
          ),

          _field(
            'Gender',
            data['gender'],
          ),

          _field(
            'Village',
            data['village'],
          ),

          _field(
            'Phone',
            data['phone'],
          ),

          _field(
            'Symptoms',
            data['symptoms'],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _savePatient,
              icon: const Icon(
                Icons.save,
              ),
              label: const Text(
                'SAVE PATIENT RECORD',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    dynamic value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value?.toString().isNotEmpty ==
                    true
                ? value.toString()
                : 'Not provided',
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
