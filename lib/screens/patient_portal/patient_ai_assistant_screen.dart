import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _answer = '';

  String _language = 'en-IN';

  final Map<String, String> _languages = {
    'en-IN': 'English',
    'ta-IN': 'தமிழ்',
    'hi-IN': 'हिन्दी',
  };

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
        localeId: _language,
      ),
      onResult: (result) {
        setState(() {
          _question = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    setState(() {
      _listening = false;
    });

    if (_question.trim().isNotEmpty) {
      await _askAI();
    }
  }

  Future<void> _askAI() async {
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
          'language': _language == 'ta-IN'
              ? 'Tamil'
              : _language == 'hi-IN'
                  ? 'Hindi'
                  : 'English',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      final answer =
          data['response']?.toString() ??
              'I could not understand the response.';

      setState(() {
        _answer = answer;
      });

      await _speak(answer);
    } catch (e) {
      _showMessage(
        'Unable to connect to Vission Health AI.',
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
    if (_language == 'ta-IN') {
      await _tts.setLanguage('ta-IN');
    } else if (_language == 'hi-IN') {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-IN');
    }

    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  void _showMessage(String message) {
    if (!mounted) return;

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
        title: const Text('AI Health Assistant'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _header(),

            const SizedBox(height: 20),

            _languageSelector(),

            const SizedBox(height: 20),

            _questionCard(),

            const SizedBox(height: 20),

            _micButton(),

            const SizedBox(height: 25),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (_answer.isNotEmpty && !_loading)
              _answerCard(),

            const SizedBox(height: 20),

            _notice(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            size: 52,
            color: Color(0xFF087F73),
          ),

          SizedBox(height: 12),

          Text(
            'Talk to Vission Health',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073B36),
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Ask your health question in your own language. '
            'The assistant will answer and read the response aloud.',
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

  Widget _languageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _language,
          isExpanded: true,

          items: _languages.entries.map(
            (entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            },
          ).toList(),

          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _language = value;
            });
          },
        ),
      ),
    );
  }

  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Your question',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _question.isEmpty
                ? 'Tap the microphone and speak...'
                : _question,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: _question.isEmpty
                  ? Colors.grey
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _micButton() {
    return Center(
      child: GestureDetector(
        onTap: _listening
            ? _stopListening
            : _startListening,

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 250),

          width: 105,
          height: 105,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _listening
                ? Colors.red
                : const Color(0xFF087F73),

            boxShadow: [
              BoxShadow(
                blurRadius:
                    _listening ? 25 : 12,
                spreadRadius:
                    _listening ? 5 : 2,
                color: (_listening
                        ? Colors.red
                        : const Color(0xFF087F73))
                    .withValues(alpha: 0.2),
              ),
            ],
          ),

          child: Icon(
            _listening
                ? Icons.stop
                : Icons.mic,
            color: Colors.white,
            size: 45,
          ),
        ),
      ),
    );
  }

  Widget _answerCard() {
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
                Icons.volume_up_rounded,
                color: Color(0xFF087F73),
              ),
              SizedBox(width: 8),
              Text(
                'Vission Health says',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            _answer,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: () => _speak(_answer),
            icon: const Icon(Icons.volume_up),
            label: const Text('READ AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade200,
        ),
      ),

      child: const Text(
        'Vission Health provides general health guidance. '
        'It does not replace a doctor or emergency medical care.',
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }
}
