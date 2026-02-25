
import 'package:hive/hive.dart';
import '../models/stroke_models.dart'; 

// ── Enums ──────────────────────────────────────────────────────

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

// ── Measurement model ──────────────────────────────────────────

class Measurement extends HiveObject {
  DateTime timestamp;

  // Legacy fields — kept for Hive backward compatibility
  double cv;
  double rmssd;

  // Core HRV fields
  double pnn50;    // same as pRR50
  double meanRR;
  double heartRate;

  // New RF v5.0 fields
  double pRR20;
  double pRR30;
  double sdsd;
  double tpr;

  // Classification results
  int afResultIndex;
  int afScore;
  int strokeScore;
  int strokeRiskIndex;
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
    this.pRR20 = 0.0,
    this.pRR30 = 0.0,
    this.sdsd  = 0.0,
    this.tpr   = 0.0,
  });

  // Convenience getters
  AfResult   get afResult   => AfResult.values[afResultIndex];
  StrokeRisk get strokeRisk => StrokeRisk.values[strokeRiskIndex];
  double     get pRR50      => pnn50; // alias
}

// ── Manual Hive adapter ────────────────────────────────────────

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 1;

  @override
  Measurement read(BinaryReader reader) {
    final timestamp       = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final cv              = reader.readDouble();
    final rmssd           = reader.readDouble();
    final pnn50           = reader.readDouble();
    final meanRR          = reader.readDouble();
    final heartRate       = reader.readDouble();
    final afResultIndex   = reader.readInt();
    final afScore         = reader.readInt();
    final strokeScore     = reader.readInt();
    final strokeRiskIndex = reader.readInt();
    final systolicBP      = reader.readBool() ? reader.readInt() : null;

    // New v5.0 fields — try/catch so old stored records still load
    double pRR20 = 0.0, pRR30 = 0.0, sdsd = 0.0, tpr = 0.0;
    try {
      pRR20 = reader.readDouble();
      pRR30 = reader.readDouble();
      sdsd  = reader.readDouble();
      tpr   = reader.readDouble();
    } catch (_) {}

    return Measurement(
      timestamp:       timestamp,
      cv:              cv,
      rmssd:           rmssd,
      pnn50:           pnn50,
      meanRR:          meanRR,
      heartRate:       heartRate,
      afResultIndex:   afResultIndex,
      afScore:         afScore,
      strokeScore:     strokeScore,
      strokeRiskIndex: strokeRiskIndex,
      systolicBP:      systolicBP,
      pRR20:           pRR20,
      pRR30:           pRR30,
      sdsd:            sdsd,
      tpr:             tpr,
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeDouble(obj.cv);
    writer.writeDouble(obj.rmssd);
    writer.writeDouble(obj.pnn50);
    writer.writeDouble(obj.meanRR);
    writer.writeDouble(obj.heartRate);
    writer.writeInt(obj.afResultIndex);
    writer.writeInt(obj.afScore);
    writer.writeInt(obj.strokeScore);
    writer.writeInt(obj.strokeRiskIndex);
    writer.writeBool(obj.systolicBP != null);
    if (obj.systolicBP != null) writer.writeInt(obj.systolicBP!);
    // v5.0 fields
    writer.writeDouble(obj.pRR20);
    writer.writeDouble(obj.pRR30);
    writer.writeDouble(obj.sdsd);
    writer.writeDouble(obj.tpr);
  }
}