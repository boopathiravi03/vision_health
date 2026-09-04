import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  bool get isListening => _speech.isListening;

  /// Initialize speech recognition.
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) {},
      );

      return _initialized;
    } catch (_) {
      return false;
    }
  }

  /// Start listening to the user's voice.
  Future<bool> startListening({
    required Function(String text) onResult,
    String? localeId,
  }) async {
    final available = await initialize();

    if (!available) {
      return false;
    }

    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
        ),
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop speech recognition.
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  /// Cancel speech recognition.
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  /// Configure text-to-speech.
  Future<void> initializeTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Helps Android choose the correct TTS engine.
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  /// Speak the AI response.
  Future<void> speak({
    required String text,
    required String language,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
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
          break;
      }

      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _tts.speak(text);
    } catch (_) {
      // TTS failure must not break the AI assistant.
    }
  }

  /// Stop current TTS playback.
  Future<void> stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Dispose speech and TTS resources.
  Future<void> dispose() async {
    try {
      await _speech.stop();
    } catch (_) {}

    try {
      await _tts.stop();
    } catch (_) {}
  }
}
