import 'package:flutter/material.dart';

import '../../models/health_scheme.dart';
import '../../services/voice_service.dart';
import 'qr_passport_screen.dart';

class SchemeScreen extends StatelessWidget {
  final List<HealthScheme> schemes;
  final String patientName;
  final String patientId;

  const SchemeScreen({
    super.key,
    required this.schemes,
    required this.patientName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: const Text(
          'Health Benefits',
        ),
      ),

      body: schemes.isEmpty
          ? const Center(
              child: Text(
                'No potentially relevant schemes found.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schemes.length,
              itemBuilder: (context, index) {
                return _SchemeCard(
                  scheme: schemes[index],
                  patientName: patientName,
                  patientId: patientId,
                );
              },
      ),
    );
  }
}

class _LanguageVoiceButton extends StatefulWidget {
  final HealthScheme scheme;

  const _LanguageVoiceButton({
    required this.scheme,
  });

  @override
  State<_LanguageVoiceButton> createState() =>
      _LanguageVoiceButtonState();
}

class _LanguageVoiceButtonState
    extends State<_LanguageVoiceButton> {
  final VoiceService _voiceService =
      VoiceService();

  String _language = 'Tamil';
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _voiceService.initializeTts();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  String _buildMessage() {
    if (_language == 'Tamil') {
      return '''
விஷன் ஹெல்த் தகவல்.

திட்டம்: ${widget.scheme.name}.

${widget.scheme.description}

அடுத்த படிகள்:

${widget.scheme.steps.asMap().entries.map(
  (entry) => '${entry.key + 1}. ${entry.value}',
).join('. ')}
''';
    }

    if (_language == 'Hindi') {
      return '''
विज़न हेल्थ जानकारी।

योजना: ${widget.scheme.name}।

${widget.scheme.description}

अगले कदम:

${widget.scheme.steps.asMap().entries.map(
  (entry) => '${entry.key + 1}. ${entry.value}',
).join('. ')}
''';
    }

    return '''
Vission Health information.

Scheme: ${widget.scheme.name}.

${widget.scheme.description}

Next steps:

${widget.scheme.steps.asMap().entries.map(
  (entry) => '${entry.key + 1}. ${entry.value}',
).join('. ')}
''';
  }

  Future<void> _speak() async {
    if (_speaking) {
      await _voiceService.stopTts();

      setState(() {
        _speaking = false;
      });

      return;
    }

    setState(() {
      _speaking = true;
    });

    await _voiceService.speak(
      text: _buildMessage(),
      language: _language,
    );

    setState(() {
      _speaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _language,

          decoration: const InputDecoration(
            labelText: 'Patient Language',
            prefixIcon: Icon(
              Icons.language,
            ),
            border: OutlineInputBorder(),
          ),

          items: const [
            DropdownMenuItem(
              value: 'Tamil',
              child: Text('தமிழ் - Tamil'),
            ),

            DropdownMenuItem(
              value: 'Hindi',
              child: Text('हिन्दी - Hindi'),
            ),

            DropdownMenuItem(
              value: 'English',
              child: Text('English'),
            ),
          ],

          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _language = value;
            });
          },
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,

          child: FilledButton.icon(
            onPressed: _speak,

            icon: Icon(
              _speaking
                  ? Icons.stop
                  : Icons.volume_up,
            ),

            label: Text(
              _speaking
                  ? 'STOP AUDIO'
                  : 'EXPLAIN TO PATIENT',
            ),
          ),
        ),
      ],
    );
  }
}


class _SchemeCard extends StatelessWidget {
  final HealthScheme scheme;
  final String patientName;
  final String patientId;

  const _SchemeCard({
    required this.scheme,
    required this.patientName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE0E9E6),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE8F6F3),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color:
                        Color(0xFF087F73),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        scheme.category,
                        style: const TextStyle(
                          color:
                              Color(0xFF087F73),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              scheme.description,
              style: const TextStyle(
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Potential Eligibility',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              scheme.eligibility,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Required Documents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...scheme.documents.map(
              (document) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color:
                          Color(0xFF087F73),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(document),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'What To Do Next',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...List.generate(
              scheme.steps.length,
              (index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            const Color(
                          0xFF087F73,
                        ),
                        child: Text(
                          '${index + 1}',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            Text(scheme.steps[index]),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QrPassportScreen(
                        scheme: scheme,
                        patientName: patientName,
                        patientId: patientId,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.qr_code_2,
                ),
                label: const Text(
                  'GENERATE BENEFIT QR',
                ),
              ),
            ),

            const SizedBox(height: 10),

            _LanguageVoiceButton(
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }
}
