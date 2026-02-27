// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      name: reader.readString(),
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      gender: reader.readString(),
      hasHypertension: reader.readBool(),
      hasDiabetes: reader.readBool(),
      hasPriorStroke: reader.readBool(),
      hasHeartFailure: reader.readBool(),
      hasVascularDisease: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.dateOfBirth.millisecondsSinceEpoch);
    writer.writeString(obj.gender);
    writer.writeBool(obj.hasHypertension);
    writer.writeBool(obj.hasDiabetes);
    writer.writeBool(obj.hasPriorStroke);
    writer.writeBool(obj.hasHeartFailure);
    writer.writeBool(obj.hasVascularDisease);
  }
}