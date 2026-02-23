import 'package:hive/hive.dart';

class PatientProfile extends HiveObject {
  String name;
  int age;
  String sex; // 'Male' | 'Female' | 'Other'
  bool hasHypertension;
  bool hasDiabetes;
  bool hasPriorStrokeTIA;
  int? systolicBP;
  int? diastolicBP;
  DateTime createdAt;

  PatientProfile({
    required this.name,
    required this.age,
    required this.sex,
    this.hasHypertension = false,
    this.hasDiabetes = false,
    this.hasPriorStrokeTIA = false,
    this.systolicBP,
    this.diastolicBP,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ── Manual Hive adapter (no build_runner needed) ───────────────
class PatientProfileAdapter extends TypeAdapter<PatientProfile> {
  @override
  final int typeId = 0;

  @override
  PatientProfile read(BinaryReader reader) {
    return PatientProfile(
      name:              reader.readString(),
      age:               reader.readInt(),
      sex:               reader.readString(),
      hasHypertension:   reader.readBool(),
      hasDiabetes:       reader.readBool(),
      hasPriorStrokeTIA: reader.readBool(),
      systolicBP:        reader.readBool() ? reader.readInt() : null,
      diastolicBP:       reader.readBool() ? reader.readInt() : null,
      createdAt:         DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, PatientProfile obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.age);
    writer.writeString(obj.sex);
    writer.writeBool(obj.hasHypertension);
    writer.writeBool(obj.hasDiabetes);
    writer.writeBool(obj.hasPriorStrokeTIA);
    writer.writeBool(obj.systolicBP != null);
    if (obj.systolicBP != null) writer.writeInt(obj.systolicBP!);
    writer.writeBool(obj.diastolicBP != null);
    if (obj.diastolicBP != null) writer.writeInt(obj.diastolicBP!);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
