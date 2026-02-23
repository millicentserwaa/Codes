import 'package:hive/hive.dart';

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

// ── Measurement model ──────────────────────────────────────────

class Measurement extends HiveObject {
  DateTime timestamp;
  double cv;
  double rmssd;
  double pnn50;
  double meanRR;
  double heartRate;
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
  });

  AfResult get afResult => AfResult.values[afResultIndex];
  StrokeRisk get strokeRisk => StrokeRisk.values[strokeRiskIndex];
}

// ── Manual Hive adapter (no build_runner needed) ───────────────

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 1;

  @override
  Measurement read(BinaryReader reader) {
    return Measurement(
      timestamp:       DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      cv:              reader.readDouble(),
      rmssd:           reader.readDouble(),
      pnn50:           reader.readDouble(),
      meanRR:          reader.readDouble(),
      heartRate:       reader.readDouble(),
      afResultIndex:   reader.readInt(),
      afScore:         reader.readInt(),
      strokeScore:     reader.readInt(),
      strokeRiskIndex: reader.readInt(),
      systolicBP:      reader.readBool() ? reader.readInt() : null,
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
  }
}
