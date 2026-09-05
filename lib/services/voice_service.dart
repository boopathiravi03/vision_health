import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(dynamic error)? onError,
  }) async {
    if (_initialized) {
      return true;
    }

    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          onStatus?.call(status);
        },
        onError: (error) {
          onError?.call(error);
        },
        debugLogging: false,
      );

      return _initialized;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startListening({
    required Function(String text) onResult,
    String? localeId,
    Function(String status)? onStatus,
    Function(dynamic error)? onError,
  }) async {
    final available = await initialize(
      onStatus: onStatus,
      onError: onError,
    );

    if (!available) {
      return false;
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }

      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 20),
        ),
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );

      return true;
    } catch (e) {
      onError?.call(e);
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);

      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      try {
        await _tts.getLanguages;
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> speak({
    required String text,
    required String language,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
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

      try {
        await _tts.setLanguage(locale);
      } catch (_) {
        await _tts.setLanguage('en-IN');
      }

      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _tts.speak(cleanText);
    } catch (_) {
      // TTS failure must never break the assistant.
    }
  }

  Future<void> stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _speech.stop();
    } catch (_) {}

    try {
      await _speech.cancel();
    } catch (_) {}

    try {
      await _tts.stop();
    } catch (_) {}
  }
}
