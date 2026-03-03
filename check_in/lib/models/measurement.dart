import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'measurement.g.dart';

@HiveType(typeId: 0)
class Measurement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final double heartRate;

  @HiveField(3)
  final int afPrediction; // 0 = Normal, 1 = Possible AF

  @HiveField(4)
  final int confidence;

  @HiveField(5)
  final String rhythm; // "Normal" or "Possible AF"

  Measurement({
    String? id,
    required this.timestamp,
    required this.heartRate,
    required this.afPrediction,
    required this.confidence,
    required this.rhythm,
  }) : id = id ?? const Uuid().v4();

  // Convert from BLE CSV data: "timestamp,mean_hr,af_prediction,confidence"
  factory Measurement.fromBLE(String raw) {
    final parts = raw.split(',');
    return Measurement(
      timestamp: DateTime.now(), // Use current time for BLE data
      heartRate: double.parse(parts[1].trim()),
      afPrediction: int.parse(parts[2].trim()),
      confidence: int.parse(parts[3].trim()),
      rhythm: int.parse(parts[2].trim()) == 1 ? 'Possible AF' : 'Normal',
    );
  }
}
