import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime dateOfBirth;

  @HiveField(2)
  final String gender; // "Male" or "Female"

  @HiveField(3)
  final bool hasHypertension;

  @HiveField(4)
  final bool hasDiabetes;

  @HiveField(5)
  final bool hasPriorStroke;

  @HiveField(6)
  final bool hasHeartFailure;

  @HiveField(7)
  final bool hasVascularDisease;

  UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.hasHypertension,
    required this.hasDiabetes,
    required this.hasPriorStroke,
    required this.hasHeartFailure,
    required this.hasVascularDisease,
  });

  // Auto-calculates age from date of birth
  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // CHA2DS2-VASc Score Calculation
  int get strokeRiskScore {
    int score = 0;

    // Congestive heart failure
    if (hasHeartFailure) score += 1;

    // Hypertension
    if (hasHypertension) score += 1;

    // Age >= 75
    if (age >= 75) score += 2;
    // Age 65-74
    else if (age >= 65) score += 1;

    // Diabetes
    if (hasDiabetes) score += 1;

    // Prior stroke/TIA (counts double)
    if (hasPriorStroke) score += 2;

    // Vascular disease
    if (hasVascularDisease) score += 1;

    // Female gender
    if (gender == 'Female') score += 1;

    return score;
  }

  // Risk level label
  String get strokeRiskLevel {
    if (gender == 'Male') {
      if (strokeRiskScore == 0) return 'Low';
      if (strokeRiskScore == 1) return 'Moderate';
      return 'High';
    } else {
      if (strokeRiskScore <= 1) return 'Low';
      if (strokeRiskScore == 2) return 'Moderate';
      return 'High';
    }
  }
}