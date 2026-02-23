import 'package:hive/hive.dart';

part 'measurement.g.dart';

// AF classification values matching firmware
enum AfResult { normal, possibleAF, inconclusive }

extension AfResultExtension on AfResult {
  String get label {
    switch (this) {
      case AfResult.normal:       return 'Normal';
      case AfResult.possibleAF:   return 'Possible AF';
      case AfResult.inconclusive: return 'Inconclusive';
    }
  }

  String get description {
    switch (this) {
      case AfResult.normal:
        return 'Your heart rhythm appears regular. No signs of atrial fibrillation detected.';
      case AfResult.possibleAF:
        return 'Irregular rhythm detected. This may indicate atrial fibrillation. Please consult a doctor.';
      case AfResult.inconclusive:
        return 'Not enough data was collected. Please retake the measurement with your fingers firmly on the pads.';
    }
  }
}

// Stroke risk category
enum StrokeRisk { low, moderate, high }

extension StrokeRiskExtension on StrokeRisk {
  String get label {
    switch (this) {
      case StrokeRisk.low:      return 'Low Risk';
      case StrokeRisk.moderate: return 'Moderate Risk';
      case StrokeRisk.high:     return 'High Risk';
    }
  }

  String get advice {
    switch (this) {
      case StrokeRisk.low:
        return 'Your stroke risk score is low. Continue regular monitoring and maintain a healthy lifestyle.';
      case StrokeRisk.moderate:
        return 'Your score indicates moderate stroke risk. Discuss your results with a healthcare provider soon.';
      case StrokeRisk.high:
        return 'Your score indicates elevated stroke risk. Please seek medical attention and share these results with your doctor.';
    }
  }
}

@HiveType(typeId: 1)
class Measurement extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  // HRV features from device
  @HiveField(1)
  double cv;         // Coefficient of Variation

  @HiveField(2)
  double rmssd;      // ms

  @HiveField(3)
  double pnn50;      // %

  @HiveField(4)
  double meanRR;     // ms

  @HiveField(5)
  double heartRate;  // BPM

  // AF classification from device (0=normal, 1=possibleAF, 2=inconclusive)
  @HiveField(6)
  int afResultIndex;

  @HiveField(7)
  int afScore;       // 0–5 from firmware

  // Stroke risk (computed by app)
  @HiveField(8)
  int strokeScore;

  @HiveField(9)
  int strokeRiskIndex; // 0=low, 1=moderate, 2=high

  // Snapshot of BP at time of measurement (may differ from profile)
  @HiveField(10)
  int? systolicBP;

  Measurement({
    required this.timestamp,
    required this.cv,
    required this.rmssd,
    required this.pnn50,
    required this.meanRR,
    required this.heartRate,
    required this.afResultIndex,
    required this.afScore,
    required this.strokeScore,
    required this.strokeRiskIndex,
    this.systolicBP,
  });

  AfResult get afResult => AfResult.values[afResultIndex];
  StrokeRisk get strokeRisk => StrokeRisk.values[strokeRiskIndex];

  // Convenience: simulated data for UI dev/testing
  factory Measurement.sample({AfResult af = AfResult.normal, int stroke = 1}) {
    return Measurement(
      timestamp: DateTime.now(),
      cv: af == AfResult.possibleAF ? 0.22 : 0.07,
      rmssd: af == AfResult.possibleAF ? 95.0 : 32.0,
      pnn50: af == AfResult.possibleAF ? 58.0 : 12.0,
      meanRR: 850,
      heartRate: 71,
      afResultIndex: af.index,
      afScore: af == AfResult.possibleAF ? 4 : 0,
      strokeScore: stroke,
      strokeRiskIndex: stroke <= 0 ? 0 : stroke <= 2 ? 1 : 2,
      systolicBP: 125,
    );
  }
}
