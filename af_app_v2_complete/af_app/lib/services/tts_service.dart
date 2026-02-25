import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

export 'tts_service_mobile.dart'
    if (dart.library.html) 'tts_service_web.dart';

class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  // state tracking for toggle behaviour
  String? _currentText;
  bool _isPaused = false;
  bool _isPlaying = false;

  bool get isPaused => _isPaused;
  bool get isPlaying => _isPlaying;
  String? get currentText => _currentText;

  /// Notifies listeners when playback state updates (play/pause/stop).
  final ValueNotifier<int> stateNotifier = ValueNotifier(0);

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // ensure speak calls are awaited/completed
    await _tts.awaitSpeakCompletion(true);

    // hook lifecycle handlers so we can update flags
    _tts.setStartHandler(() {
      _isPlaying = true;
      _isPaused = false;
      stateNotifier.value++;
    });
    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      stateNotifier.value++;
    });
    _tts.setPauseHandler(() {
      _isPaused = true;
      stateNotifier.value++;
    });
    _tts.setContinueHandler(() {
      _isPaused = false;
      stateNotifier.value++;
    });

    _initialized = true;
  }

  /// Speak the given [text].
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    // debug logging
    // ignore: avoid_print
    print('[TtsService] speak requested: "$text"');


    await init();
    // the flutter_tts implementation can drop long strings, so split
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;
      final result = await _tts.speak(sentence);
      // ignore: avoid_print
      print('[TtsService] spoke segment: "$sentence" result=$result');
    }
  }

  /// Stop speaking immediately and clear state.
  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
    stateNotifier.value++;
  }

  /// Pause current speech, if supported.
  Future<void> pause() async {
    await _tts.pause();
    _isPaused = true;
    stateNotifier.value++;
  }

  /// Resume speech after pausing.
  Future<void> resume() async {
    // flutter_tts doesn't support resume; restart speaking instead
    if (_currentText != null) {
      await _tts.speak(_currentText!);
      _isPaused = false;
      stateNotifier.value++;
    }
  }

  /// Behaves like a play/pause toggle for [text].
  ///
  /// * If a different text is passed, speech restarts from beginning.
  /// * If the same text is playing, pause/resume toggles.
  /// * If the same text finished, it starts over again.
  Future<void> togglePlayPause(String text) async {
    if (_currentText == text && _isPlaying) {
      if (_isPaused) {
        await resume();
      } else {
        await pause();
      }
    } else {
      await speak(text);
    }
  }
}
