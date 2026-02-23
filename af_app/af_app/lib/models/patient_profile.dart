import 'package:hive/hive.dart';

part 'patient_profile.g.dart';

@HiveType(typeId: 0)
class PatientProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String sex; // 'Male' | 'Female' | 'Other'

  @HiveField(3)
  bool hasHypertension;

  @HiveField(4)
  bool hasDiabetes;

  @HiveField(5)
  bool hasPriorStrokeTIA;

  @HiveField(6)
  int? systolicBP; // mmHg — nullable, entered manually

  @HiveField(7)
  int? diastolicBP;

  @HiveField(8)
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
