import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../services/health_assistant_service.dart';
import '../../services/voice_service.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() =>
      _HealthAssistantScreenState();
}

class _HealthAssistantScreenState
    extends State<HealthAssistantScreen> {
  final TextEditingController _queryController =
      TextEditingController();

  final VoiceService _voiceService = VoiceService();

  String _language = 'English';

  bool _loading = false;
  bool _isListening = false;
  bool _speaking = false;

  String? _response;
  String? _error;

  Timer? _listeningTimer;

  @override
  void initState() {
    super.initState();

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
    await _voiceService.initializeTts();
  }

  // ------------------------------------------------------------
  // LANGUAGE
  // ------------------------------------------------------------

  String _speechLocale() {
    switch (_language) {
      case 'Tamil':
        return 'ta_IN';

      case 'Hindi':
        return 'hi_IN';

      case 'English':
      default:
        return 'en_IN';
    }
  }

  // ------------------------------------------------------------
  // TEXT ASK
  // ------------------------------------------------------------

  Future<void> _ask() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error = 'Please enter a health question.';
      });

      return;
    }

    await _sendQuestion(query);
  }

  // ------------------------------------------------------------
  // VOICE ASK
  // ------------------------------------------------------------

  Future<void> _startVoiceInput() async {
    if (_loading) {
      return;
    }

    setState(() {
      _error = null;
      _response = null;
      _isListening = true;
    });

    final started = await _voiceService.startListening(
      localeId: _speechLocale(),
      onResult: (text) {
        if (!mounted) {
          return;
        }

        if (text.trim().isNotEmpty) {
          setState(() {
            _queryController.text = text;
            _queryController.selection =
                TextSelection.fromPosition(
              TextPosition(
                offset: _queryController.text.length,
              ),
            );
          });
        }
      },
    );

    if (!mounted) {
      return;
    }

    if (!started) {
      setState(() {
        _isListening = false;
        _error =
            'Microphone or speech recognition is unavailable. '
            'Please check microphone permission.';
      });

      return;
    }

    // Automatically stop listening after 15 seconds.
    _listeningTimer?.cancel();

    _listeningTimer = Timer(
      const Duration(seconds: 15),
      () async {
        if (_isListening) {
          await _stopVoiceInput();
        }
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    _listeningTimer?.cancel();

    await _voiceService.stopListening();

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error =
            'I could not hear a question. Please try speaking again.';
      });

      return;
    }

    // Automatically send the recognized question to AI.
    await _sendQuestion(query);
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _stopVoiceInput();
    } else {
      await _startVoiceInput();
    }
  }

  // ------------------------------------------------------------
  // SEND TO BACKEND
  // ------------------------------------------------------------

  Future<void> _sendQuestion(String query) async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _response = null;
      _speaking = false;
    });

    await _voiceService.stopTts();

    try {
      final result = await HealthAssistantService.ask(
        query: query,
        language: _language,
      ).timeout(
        const Duration(seconds: 45),
      );

      if (!mounted) {
        return;
      }

      final response =
          result['response']?.toString().trim() ?? '';

      if (response.isEmpty) {
        throw Exception(
          'The AI service returned an empty response.',
        );
      }

      setState(() {
        _response = response;
        _loading = false;
      });

      // Speak the AI answer automatically.
      await _speakResponse(response);
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
            'The AI service took too long to respond. '
            'Please try again.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }

      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  // ------------------------------------------------------------
  // TEXT TO SPEECH
  // ------------------------------------------------------------

  Future<void> _speakResponse(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _speaking = true;
    });

    await _voiceService.speak(
      text: _removeMarkdownForSpeech(text),
      language: _language,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _speaking = false;
    });
  }

  String _removeMarkdownForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'__'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'_'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .trim();
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stopTts();

    if (!mounted) {
      return;
    }

    setState(() {
      _speaking = false;
    });
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F0EE),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'AI Health Assistant',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Tamil',
                    child: Text('Tamil'),
                  ),
                  DropdownMenuItem(
                    value: 'Hindi',
                    child: Text('Hindi'),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _language = value;
                        });
                      },
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ),
          child: Column(
            children: [
              _headerCard(),

              const SizedBox(height: 18),

              _voiceAssistantCard(),

              const SizedBox(height: 18),

              _inputCard(),

              const SizedBox(height: 18),

              if (_loading) _loadingCard(),

              if (_error != null) ...[
                if (_loading) const SizedBox(height: 14),
                _errorCard(),
              ],

              if (_response != null) ...[
                if (_loading || _error != null)
                  const SizedBox(height: 14),
                _responseCard(),
              ],

              const SizedBox(height: 14),

              _disclaimerCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F4F1),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 42,
              color: Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Talk to Vission AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF075E55),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Speak naturally and hear simple '
            'health guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.45,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // VOICE CARD
  // ------------------------------------------------------------

  Widget _voiceAssistantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        26,
        22,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _isListening
                  ? const Color(0xFFD9F5F0)
                  : const Color(0xFFE8F7F4),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Icon(
              _isListening
                  ? Icons.mic
                  : Icons.record_voice_over,
              size: 58,
              color: const Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _isListening
                ? 'Listening...'
                : 'Ask Vission AI',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isListening
                ? 'Speak your health question clearly.'
                : 'Ask about your health and receive '
                    'simple guidance.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: _loading ? null : _toggleVoice,
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF087F73),
                disabledBackgroundColor:
                    Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Icon(
                _isListening
                    ? Icons.stop
                    : Icons.mic,
                color: Colors.white,
              ),
              label: Text(
                _isListening
                    ? 'STOP & ASK'
                    : 'ASK BY VOICE',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          if (_isListening) ...[
            const SizedBox(height: 12),

            const LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF087F73),
              backgroundColor: Color(0xFFE0EFED),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT INPUT
  // ------------------------------------------------------------

  Widget _inputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Or type your question',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _queryController,
            enabled: !_loading,
            maxLines: 4,
            textInputAction:
                TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'Example: What should I do for mild fever?',
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF087F73),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _loading ? null : _toggleVoice,
                  icon: Icon(
                    _isListening
                        ? Icons.stop
                        : Icons.mic,
                  ),
                  label: Text(
                    _isListening
                        ? 'STOP'
                        : 'VOICE',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF087F73),
                    side: const BorderSide(
                      color: Color(0xFF087F73),
                    ),
                    minimumSize:
                        const Size(0, 52),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _loading ? null : _ask,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _loading
                        ? 'ASKING...'
                        : 'ASK',
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF087F73),
                    minimumSize:
                        const Size(0, 52),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LOADING
  // ------------------------------------------------------------

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF087F73),
          ),

          const SizedBox(height: 14),

          const Text(
            'Vission AI is thinking...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Please wait for the health guidance.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RESPONSE
  // ------------------------------------------------------------

  Widget _responseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0ECEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F4F1),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF087F73),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Vission AI',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                tooltip: _speaking
                    ? 'Stop speaking'
                    : 'Read aloud',
                onPressed: _speaking
                    ? _stopSpeaking
                    : () {
                        _speakResponse(
                          _response!,
                        );
                      },
                icon: Icon(
                  _speaking
                      ? Icons.stop_circle
                      : Icons.volume_up,
                  color: const Color(0xFF087F73),
                ),
              ),
            ],
          ),

          const Divider(height: 28),

          MarkdownBody(
            data: _response!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                height: 1.55,
                color: Colors.black87,
              ),
              h1: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
              ),
              tableHead: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              tableBody: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (_speaking)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F6),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: Color(0xFF087F73),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Vission AI is speaking...',
                    style: TextStyle(
                      color: Color(0xFF087F73),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DISCLAIMER
  // ------------------------------------------------------------

  Widget _disclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1D878),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE49B00),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Vission AI provides general health '
              'guidance and is not a diagnosis. '
              'For serious or emergency symptoms, '
              'contact a healthcare professional.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------

  @override
  void dispose() {
    _listeningTimer?.cancel();

    _queryController.dispose();

    _voiceService.dispose();

    super.dispose();
  }
}
