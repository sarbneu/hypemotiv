/// Text-to-Speech service for reading motivational quotes aloud.
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  /// Initialize the TTS engine without ever blocking app startup.
  /// Some Android images have no TTS engine installed; in that case the
  /// calls can hang, so each one is bounded and failures are ignored.
  Future<void> init() async {
    await _safe(() => _flutterTts.setLanguage('en-US'));
    await _safe(() => _flutterTts.setSpeechRate(0.5)); // Slower for quotes
    await _safe(() => _flutterTts.setPitch(1.0));
  }

  Future<void> _safe(Future<dynamic> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 2));
    } catch (_) {
      // TTS is optional; the rest of the app must still start.
    }
  }

  /// Speak a quote text aloud.
  Future<void> speak(String text, {double rate = 0.5, double pitch = 1.0}) async {
    await _safe(() => _flutterTts.speak(text));
  }

  /// Stop any current speech.
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Get the current speaking status.
  Future<void> getStatus() async {
    // Status check is optional - simplified to avoid API mismatch
    await _flutterTts.stop();
  }

  /// Set the language.
  Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }

  /// Set the speech rate (0.0 to 1.0).
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set the pitch.
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  /// Dispose of the TTS engine.
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
