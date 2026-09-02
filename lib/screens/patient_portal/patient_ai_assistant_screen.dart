import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PatientAiAssistantScreen extends StatefulWidget {
  const PatientAiAssistantScreen({super.key});

  @override
  State<PatientAiAssistantScreen> createState() =>
      _PatientAiAssistantScreenState();
}

class _PatientAiAssistantScreenState
    extends State<PatientAiAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _listening = false;
  String _question = '';

  final List<Map<String, String>> _messages = [];

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();

      setState(() {
        _listening = false;
      });

      if (_question.trim().isNotEmpty) {
        _askAI();
      }

      return;
    }

    final available = await _speech.initialize();

    if (!available) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available.'),
        ),
      );

      return;
    }

    setState(() {
      _listening = true;
      _question = '';
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en-IN',
      ),
      onResult: (result) {
        setState(() {
          _question = result.recognizedWords;
        });
      },
    );
  }

  void _askAI() {
    final question = _question.trim();

    if (question.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': question,
      });

      _messages.add({
        'role': 'ai',
        'text':
            'I understand your question. Please follow the care instructions given by your healthcare worker. If you have severe or worsening symptoms, please contact your PHC or doctor.',
      });

      _question = '';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.smart_toy,
                    color: Color(0xFF087F73),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Ask your health question by speaking naturally.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Tap the microphone and ask a question.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 330,
                          ),
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF087F73)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_question.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _question,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 25,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: _toggleListening,
                icon: Icon(
                  _listening
                      ? Icons.stop
                      : Icons.mic,
                ),
                label: Text(
                  _listening
                      ? 'STOP & ASK'
                      : 'ASK BY VOICE',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
