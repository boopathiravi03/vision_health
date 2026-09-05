import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../services/health_assistant_service.dart';

class PatientAiAssistantScreen extends StatefulWidget {
  const PatientAiAssistantScreen({super.key});

  @override
  State<PatientAiAssistantScreen> createState() =>
      _PatientAiAssistantScreenState();
}

class _PatientAiAssistantScreenState
    extends State<PatientAiAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;
  bool _loading = false;

  String _question = '';
  String _language = 'English';

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  String _localeForLanguage() {
    switch (_language) {
      case 'Tamil':
        return 'ta-IN';
      case 'Hindi':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }

  String _ttsLocaleForLanguage() {
    switch (_language) {
      case 'Tamil':
        return 'ta-IN';
      case 'Hindi':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }

  Future<void> _toggleListening() async {
    if (_loading) return;

    if (_listening) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _listening = false;
      });

      if (_question.trim().isNotEmpty) {
        await _askAI();
      }

      return;
    }

    final available = await _speech.initialize();

    if (!available) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available on this device.',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _listening = true;
      _question = '';
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _localeForLanguage(),
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _question = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _askAI() async {
    final question = _question.trim();

    if (question.isEmpty) return;

    setState(() {
      _loading = true;

      _messages.add({
        'role': 'user',
        'text': question,
      });

      _question = '';
    });

    try {
      final answer = await HealthAssistantService().askAssistant(
        query: question,
        language: _language,
      );

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': answer,
        });

        _loading = false;
      });

      await _speak(answer);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        _messages.add({
          'role': 'ai',
          'text':
              'Sorry, I could not connect to the health assistant. Please try again.',
        });
      });
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();

    await _tts.setLanguage(
      _ttsLocaleForLanguage(),
    );

    await _tts.speak(text);
  }

  Future<void> _changeLanguage(String language) async {
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _language = language;
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'AI Health Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Tamil',
                    child: Text('தமிழ்'),
                  ),
                  DropdownMenuItem(
                    value: 'Hindi',
                    child: Text('हिन्दी'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changeLanguage(value);
                  }
                },
              ),
            ),
          ),
        ],
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFF087F73),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Talk to Vission AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _language == 'Tamil'
                            ? 'உங்கள் உடல்நலக் கேள்வியை பேசுங்கள்.'
                            : _language == 'Hindi'
                                ? 'अपना स्वास्थ्य प्रश्न बोलकर पूछें।'
                                : 'Speak naturally and hear simple health guidance.',
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      final isUser =
                          message['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 340,
                          ),
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF087F73)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(18),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: const Color(
                                      0xFFE0E9E6,
                                    ),
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),

                              if (!isUser) ...[
                                const SizedBox(height: 10),

                                Align(
                                  alignment:
                                      Alignment.bottomRight,
                                  child: IconButton(
                                    onPressed: () {
                                      _speak(
                                        message['text'] ?? '',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      color: Color(
                                        0xFF087F73,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_listening && _question.isNotEmpty)
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
              child: Row(
                children: [
                  const Icon(
                    Icons.mic,
                    color: Color(0xFF087F73),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _question,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF087F73),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Vission AI is thinking...',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              25,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed:
                    _loading ? null : _toggleListening,
                icon: Icon(
                  _listening
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                ),
                label: Text(
                  _listening
                      ? 'STOP & ASK'
                      : 'ASK BY VOICE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                size: 45,
                color: Color(0xFF087F73),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Ask Vission AI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _language == 'Tamil'
                  ? 'உங்கள் உடல்நலக் கேள்வியை கேளுங்கள்.'
                  : _language == 'Hindi'
                      ? 'अपने स्वास्थ्य से जुड़ा सवाल पूछें।'
                      : 'Ask about your health and receive simple guidance.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
