import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../services/ai_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState
    extends State<VoiceAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AIService _aiService = AIService();

  bool _available = false;
  bool _listening = false;
  bool _loading = false;

  String _selectedLanguage = 'Tamil';
  String _text = '';
  String _response = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    _available = await _speech.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_available) {
      _showMessage(
        'Speech recognition is not available on this device.',
      );
      return;
    }

    setState(() {
      _listening = true;
      _text = '';
      _response = '';
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _selectedLanguage == 'Tamil'
            ? 'ta_IN'
            : 'en_IN',
      ),
      onResult: (result) {
        if (mounted) {
          setState(() {
            _text = result.recognizedWords;
          });
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _listening = false;
    });

    if (_text.trim().isEmpty) {
      _showMessage('Please speak something first.');
      return;
    }

    await _askAI();
  }

  Future<void> _askAI() async {
    setState(() {
      _loading = true;
    });

    try {
      final answer = await _aiService.analyzeHealthQuery(
        _text,
        language: _selectedLanguage,
      );

      if (!mounted) return;

      setState(() {
        _response = answer;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to connect to Vission Health AI.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(
          'Voice Health Assistant',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),

            const SizedBox(height: 22),

            _buildLanguageSelector(),

            const SizedBox(height: 24),

            _buildMicrophone(),

            const SizedBox(height: 24),

            _buildTranscript(),

            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            if (_response.isNotEmpty && !_loading) ...[
              const SizedBox(height: 24),
              _buildAIResponse(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over_rounded,
            size: 40,
            color: Color(0xFF087F73),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Speak naturally',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF073B36),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Describe the patient concern in your local language.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'Tamil',
              label: Text('தமிழ்'),
              icon: Icon(Icons.translate),
            ),
            ButtonSegment(
              value: 'English',
              label: Text('English'),
              icon: Icon(Icons.language),
            ),
          ],
          selected: {_selectedLanguage},
          onSelectionChanged: (value) {
            setState(() {
              _selectedLanguage = value.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMicrophone() {
    return Column(
      children: [
        GestureDetector(
          onTap: _listening
              ? _stopListening
              : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 145,
            width: 145,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening
                  ? Colors.red.shade400
                  : const Color(0xFF087F73),
              boxShadow: [
                BoxShadow(
                  blurRadius: _listening ? 25 : 12,
                  spreadRadius: _listening ? 8 : 2,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Icon(
              _listening
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              size: 65,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _listening
              ? 'Listening... Tap to stop'
              : 'Tap to speak',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscript() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E9E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you said',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _text.isEmpty
                ? 'Your speech will appear here...'
                : _text,
            style: TextStyle(
              color: _text.isEmpty
                  ? Colors.grey
                  : Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResponse() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF087F73),
              ),
              const SizedBox(width: 10),
              Text(
                'Vission AI Guidance',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _response,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'AI guidance is a screening aid, not a medical diagnosis. '
              'Urgent symptoms should be referred to a qualified healthcare professional.',
              style: TextStyle(
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
