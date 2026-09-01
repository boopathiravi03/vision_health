import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt;

import '../../services/speech_form_service.dart';
import '../patient/health_passport_screen.dart';

class SpeechToFormScreen extends StatefulWidget {
  const SpeechToFormScreen({
    super.key,
  });

  @override
  State<SpeechToFormScreen> createState() =>
      _SpeechToFormScreenState();
}

class _SpeechToFormScreenState
    extends State<SpeechToFormScreen> {
  final stt.SpeechToText speech =
      stt.SpeechToText();

  bool listening = false;
  bool processing = false;

  String transcript = '';

  Map<String, dynamic>? result;

  Future<void> startListening() async {
    final available =
        await speech.initialize();

    if (!available) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is unavailable.',
          ),
        ),
      );

      return;
    }

    setState(() {
      listening = true;
      transcript = '';
      result = null;
    });

    await speech.listen(
      onResult: (value) {
        setState(() {
          transcript =
              value.recognizedWords;
        });
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      listening = false;
    });
  }

  Future<void> processWithAI() async {
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please record or enter a patient note first.',
          ),
        ),
      );

      return;
    }

    setState(() {
      processing = true;
    });

    try {
      final data =
          await SpeechFormService
              .extractForm(
        transcript,
      );

      if (!mounted) return;

      setState(() {
        result = data;
        processing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'AI processing failed: $e',
          ),
        ),
      );
    }
  }

  Future<void> savePatient() async {
    if (result == null) {
      return;
    }

    try {
      setState(() {
        processing = true;
      });

      final symptoms = result!['symptoms'];

      final redFlags = result!['red_flags'];

      final docRef = await FirebaseFirestore
          .instance
          .collection('patients')
          .add({
        'name': result!['patient_name'] ?? '',

        'age': result!['age'],

        'gender': result!['gender'] ?? '',

        'village': result!['village'] ?? '',

        'symptoms':
            symptoms is List ? symptoms : [],

        'duration': result!['duration'] ?? '',

        'severity': result!['severity'] ?? '',

        'redFlags':
            redFlags is List ? redFlags : [],

        'followUpRequired':
            result!['follow_up_required'] ??
                false,

        'transcript': transcript,

        'createdAt':
            FieldValue.serverTimestamp(),

        'source': 'ASHA_AI_SPEECH_FORM',

        'status': 'confirmed',
      });

      final patientId = docRef.id;

      if (!mounted) return;

      setState(() {
        processing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Patient saved successfully.\nID: $patientId',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HealthPassportScreen(
            patientId: patientId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Speech-to-Form',
        ),
      ),

      backgroundColor:
          const Color(0xFFF5F9F8),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            _voiceCard(),

            const SizedBox(height: 16),

            _transcriptCard(),

            if (result != null) ...[
              const SizedBox(height: 16),
              _resultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _voiceCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),
      ),

      child: Column(
        children: [
          CircleAvatar(
            radius: 38,

            backgroundColor:
                listening
                    ? Colors.red.shade50
                    : const Color(
                        0xFFE8F6F3,
                      ),

            child: Icon(
              listening
                  ? Icons.mic
                  : Icons.mic_none,

              size: 40,

              color: listening
                  ? Colors.red
                  : const Color(
                      0xFF087F73,
                    ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            listening
                ? 'Listening...'
                : 'Speak Patient Notes',
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Speak naturally. Vission Health will convert your notes into a structured form.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: listening
                  ? stopListening
                  : startListening,

              icon: Icon(
                listening
                    ? Icons.stop
                    : Icons.mic,
              ),

              label: Text(
                listening
                    ? 'STOP RECORDING'
                    : 'START SPEAKING',
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed:
                  processing
                      ? null
                      : processWithAI,

              icon: processing
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
                processing
                    ? 'AI PROCESSING...'
                    : 'EXTRACT FORM WITH AI',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcriptCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Transcript',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            transcript.isEmpty
                ? 'Your spoken notes will appear here...'
                : transcript,

            style: TextStyle(
              color: transcript.isEmpty
                  ? Colors.grey
                  : Colors.black87,

              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final data = result!;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),
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
                'AI Extracted Form',
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
            'Patient Name',
            data['patient_name'],
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
            'Symptoms',
            data['symptoms'],
          ),

          _field(
            'Duration',
            data['duration'],
          ),

          _field(
            'Severity',
            data['severity'],
          ),

          _field(
            'Red Flags',
            data['red_flags'],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF8E1),

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: const Text(
              'Review the extracted information before saving the patient record.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed:
                  processing ? null : savePatient,

              icon: const Icon(
                Icons.check,
              ),

              label: const Text(
                'CONFIRM & SAVE',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String title,
    dynamic value,
  ) {
    String text;

    if (value is List) {
      text = value.join(', ');
    } else {
      text =
          value?.toString() ?? '';
    }

    if (text.isEmpty) {
      text = 'Not provided';
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
