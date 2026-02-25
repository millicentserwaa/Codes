import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> init({
    String? language, // e.g. "en-US"
    double? speechRate, // 0.0 - 1.0 (plugin dependent)
    double? pitch, // 0.5 - 2.0
    double? volume, // 0.0 - 1.0
  }) async {
    if (_initialized) return;

    if (language != null) await _tts.setLanguage(language);
    if (speechRate != null) await _tts.setSpeechRate(speechRate);
    if (pitch != null) await _tts.setPitch(pitch);
    if (volume != null) await _tts.setVolume(volume);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) {
      await init(language: "en-US", speechRate: 0.5, pitch: 1.0, volume: 1.0);
    }
    await _tts.stop(); // prevents overlapping
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}