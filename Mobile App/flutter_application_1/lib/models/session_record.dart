import 'package:hive/hive.dart';

part 'session_record.g.dart';

@HiveType(typeId: 3)
enum AfResult {
  @HiveField(0)
  ok,

  @HiveField(1)
  notOk,

  @HiveField(2)
  inconclusive,
}

@HiveType(typeId: 4)
class SessionRecord extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final AfResult afResult;

  @HiveField(3)
  final int confidence; // 0-100

  @HiveField(4)
  final int signalQuality; // 0-100 (can match confidence if you want)

  @HiveField(5)
  final double heartRateBpm;

  @HiveField(6)
  final double? spo2;

  @HiveField(7)
  final int? spo2Confidence; // 0-100

  @HiveField(8)
  final double? ecgRmssdMs;

  @HiveField(9)
  final double? ppgRmssdMs;

  @HiveField(10)
  final int acceptedWindows;

  @HiveField(11)
  final int totalWindows;

  @HiveField(12)
  final List<String> flags;

  @HiveField(13)
  final String? deviceId;

  @HiveField(14)
  final String? firmwareVersion;

  @HiveField(15)
  final int? durationSec;

  SessionRecord({
    required this.sessionId,
    required this.timestamp,
    required this.afResult,
    required this.confidence,
    required this.signalQuality,
    required this.heartRateBpm,
    required this.acceptedWindows,
    required this.totalWindows,
    required this.flags,
    this.spo2,
    this.spo2Confidence,
    this.ecgRmssdMs,
    this.ppgRmssdMs,
    this.deviceId,
    this.firmwareVersion,
    this.durationSec,
  });
}
