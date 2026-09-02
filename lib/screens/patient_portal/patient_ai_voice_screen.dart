import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class PatientAiVoiceScreen extends StatefulWidget {
  const PatientAiVoiceScreen({super.key});

  @override
  State<PatientAiVoiceScreen> createState() =>
      _PatientAiVoiceScreenState();
}

class _PatientAiVoiceScreenState
    extends State<PatientAiVoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;
  bool _loading = false;

  String _question = '';
  String _answer = '';

  @override
  void initState() {
    super.initState();

    _tts.setSpeechRate(0.48);
    _tts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize();

    if (!available) {
      _showMessage('Speech recognition is not available.');
      return;
    }

    setState(() {
      _listening = true;
      _question = '';
      _answer = '';
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en-IN',
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _question = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _listening = false;
    });

    if (_question.trim().isNotEmpty) {
      await _askAI();
    }
  }

  Future<void> _askAI() async {
    if (_question.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _answer = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://vision-health.onrender.com/health-assistant',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': _question,
          'language': 'English',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      final answer =
          decoded['response']?.toString() ??
              'I could not understand the response.';

      if (!mounted) return;

      setState(() {
        _answer = answer;
      });

      await _speak(answer);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to connect to Vission AI.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();

    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          'Talk to Vission AI',
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

            const SizedBox(height: 24),

            _questionCard(),

            const SizedBox(height: 20),

            _micButton(),

            const SizedBox(height: 12),

            Text(
              _listening
                  ? 'Listening... Tap again to stop'
                  : 'Tap the microphone and speak',
              style: TextStyle(
                color: _listening
                    ? Colors.red
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 28),

              const CircularProgressIndicator(
                color: Color(0xFF087F73),
              ),

              const SizedBox(height: 12),

              const Text(
                'Vission AI is preparing your answer...',
              ),
            ],

            if (_answer.isNotEmpty) ...[
              const SizedBox(height: 28),

              _answerCard(),
            ],

            const SizedBox(height: 24),

            _disclaimer(),
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
              Icons.smart_toy_rounded,
              size: 38,
              color: Color(0xFF087F73),
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Ask Vission AI',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073B36),
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Speak naturally. Vission AI will listen and reply with voice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard() {
    return _messageCard(
      title: 'You asked',
      icon: Icons.person_rounded,
      text: _question.isEmpty
          ? 'Your question will appear here...'
          : _question,
    );
  }

  Widget _answerCard() {
    return _messageCard(
      title: 'Vission AI',
      icon: Icons.smart_toy_rounded,
      text: _answer,
      showSpeaker: true,
    );
  }

  Widget _messageCard({
    required String title,
    required IconData icon,
    required String text,
    bool showSpeaker = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF087F73),
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              if (showSpeaker)
                IconButton(
                  onPressed: () => _speak(_answer),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFF087F73),
                  ),
                ),

              if (showSpeaker)
                IconButton(
                  onPressed: _stopSpeaking,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            text,
            style: TextStyle(
              color: text.contains('appear here')
                  ? Colors.grey
                  : Colors.black87,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _micButton() {
    return GestureDetector(
      onTap: _listening
          ? _stopListening
          : _startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening
              ? Colors.red
              : const Color(0xFF087F73),
          boxShadow: [
            BoxShadow(
              blurRadius: _listening ? 25 : 12,
              spreadRadius: _listening ? 6 : 2,
              color: (_listening
                      ? Colors.red
                      : const Color(0xFF087F73))
                  .withValues(alpha: .20),
            ),
          ],
        ),
        child: Icon(
          _listening
              ? Icons.stop_rounded
              : Icons.mic_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }

  Widget _disclaimer() {
    return const Text(
      'Vission AI provides general information only. '
      'It does not replace a doctor or healthcare professional. '
      'For emergencies, seek immediate medical care.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
