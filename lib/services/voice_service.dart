import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    _initialized = await _speech.initialize();
    return _initialized;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    String? localeId,
  }) async {
    final available = await initialize();

    if (!available) {
      return;
    }

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  Future<void> initializeTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak({
    required String text,
    required String language,
  }) async {
    await _tts.stop();

    String locale;

    switch (language.toLowerCase()) {
      case 'tamil':
        locale = 'ta-IN';
        break;

      case 'hindi':
        locale = 'hi-IN';
        break;

      case 'english':
      default:
        locale = 'en-IN';
    }

    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
  }
}
