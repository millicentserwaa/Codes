// import 'dart:html' as html;

// class TtsService {
//   Future<void> speak(String text) async {
//     final synth = html.window.speechSynthesis;
//     final utter = html.SpeechSynthesisUtterance(text);
//     synth?.speak(utter);
//   }

//   Future<void> stop() async {
//     html.window.speechSynthesis?.cancel();
//   }
// }

import 'dart:html' as html;

class TtsService {
  bool _initialized = false;

  Future<void> init({
    String? language, // e.g. "en-US"
    double? speechRate, // typically 0.1 - 10
    double? pitch, // 0 - 2
    double? volume, // 0 - 1
  }) async {
    // Web Speech API applies settings per utterance, but we keep init for API parity
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();

    final synth = html.window.speechSynthesis;
    synth?.cancel(); // stop any previous speech

    final utter = html.SpeechSynthesisUtterance(text)
      ..lang = "en-US"
      ..rate = 1.0
      ..pitch = 1.0
      ..volume = 1.0;

    synth?.speak(utter);
  }

  Future<void> stop() async {
    html.window.speechSynthesis?.cancel();
  }
}