import 'package:flutter_tts/flutter_tts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  // ── Initialize ───────────────────────────────────────────
  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slightly slower for 40+ users
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  // ── Core speak method ────────────────────────────────────
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // ── Measurement result ───────────────────────────────────
  Future<void> speakMeasurement(Measurement measurement) async {
    final hr = measurement.heartRate.toStringAsFixed(0);
    final rhythm = measurement.rhythm;
    final confidence = measurement.confidence;

    String message;

    if (measurement.afPrediction == 1) {
      message =
          'Measurement complete. Your heart rate is $hr beats per minute. '
          'A possible irregular rhythm has been detected. '
          'Confidence level is $confidence percent. '
          'Please consult a healthcare professional.';
    } else {
      message =
          'Measurement complete. Your heart rate is $hr beats per minute. '
          'Your rhythm appears normal. '
          'Confidence level is $confidence percent.';
    }

    await speak(message);
  }

  // ── Stroke risk result ───────────────────────────────────
  Future<void> speakRiskScore(UserProfile profile) async {
    final score = profile.strokeRiskScore;
    final level = profile.strokeRiskLevel;
    final age = profile.age;

    String message =
        'Your CHA 2 DS 2 VASc stroke risk score is $score out of 9. '
        'This indicates a $level risk level. '
        'You are $age years old. ';

    if (level == 'High') {
      message +=
          'Please consult your healthcare provider as soon as possible '
          'to discuss stroke prevention options.';
    } else if (level == 'Moderate') {
      message +=
          'We recommend discussing stroke prevention options '
          'with your healthcare provider.';
    } else {
      message +=
          'Continue maintaining a healthy lifestyle '
          'and monitor regularly.';
    }

    await speak(message);
  }

  // ── Sync complete ────────────────────────────────────────
  Future<void> speakSyncComplete(int count) async {
    await speak(
      'Sync complete. $count measurement${count == 1 ? '' : 's'} '
      'received from your AF Monitor device.',
    );
  }

  // ── Connection status ────────────────────────────────────
  Future<void> speakConnectionStatus(bool connected) async {
    if (connected) {
      await speak('AF Monitor device connected successfully.');
    } else {
      await speak('Device disconnected.');
    }
  }

  // ── No readings ──────────────────────────────────────────
  Future<void> speakNoReadings() async {
    await speak(
      'No readings available yet. '
      'Please connect your AF Monitor device and sync to get started.',
    );
  }

  void dispose() {
    _tts.stop();
  }
}