library;
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  static const List<String> characters = <String>[
    'Calm',
    'Cheerful',
    'Firm',
    'Radio',
  ];

  static const Map<String, double> _rates = <String, double>{
    'Calm': 0.45,
    'Cheerful': 0.70,
    'Firm': 0.55,
    'Radio': 0.90,
  };

  static const Map<String, double> _pitches = <String, double>{
    'Calm': 1.0,
    'Cheerful': 1.25,
    'Firm': 0.85,
    'Radio': 0.7,
  };

  Future<void> init() async {
    await _safe(() => _flutterTts.setLanguage('en-US'));
    await _safe(() => _flutterTts.setSpeechRate(0.5));
    await _safe(() => _flutterTts.setPitch(1.0));
  }

  Future<void> _safe(Future<dynamic> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 2));
    } catch (_) {
    }
  }

  Future<void> speak(String text, {double rate = 0.5, double pitch = 1.0}) async {
    await _safe(() => _flutterTts.setSpeechRate(rate));
    await _safe(() => _flutterTts.setPitch(pitch));
    await _safe(() => _flutterTts.speak(text));
  }

  Future<void> speakWithCharacter(String text, String character) async {
    final String name = characters.contains(character) ? character : 'Calm';
    await speak(
      text,
      rate: _rates[name] ?? 0.5,
      pitch: _pitches[name] ?? 1.0,
    );
  }

  Future<List<String>> getVoices() async {
    try {
      final dynamic result = await _flutterTts.getVoices.timeout(
        const Duration(seconds: 3),
      );
      if (result is! List) return const <String>[];
      return result
          .map((dynamic v) => v is Map ? (v['name'] ?? '').toString() : '')
          .where((String name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> getStatus() async {
    await _flutterTts.stop();
  }

  Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }

  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
