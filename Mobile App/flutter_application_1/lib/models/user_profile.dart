import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
enum AgeGroup {
  @HiveField(0)
  under40,

  @HiveField(1)
  from40to59,

  @HiveField(2)
  above60,
}

@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String profileId; // keep as "local"

  @HiveField(1)
  final AgeGroup ageGroup;

  @HiveField(2)
  final bool hasHypertension;

  @HiveField(3)
  final bool hasDiabetes;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  UserProfile({
    required this.profileId,
    required this.ageGroup,
    required this.hasHypertension,
    required this.hasDiabetes,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  UserProfile copyWith({
    AgeGroup? ageGroup,
    bool? hasHypertension,
    bool? hasDiabetes,
    String? notes,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      profileId: profileId,
      ageGroup: ageGroup ?? this.ageGroup,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
