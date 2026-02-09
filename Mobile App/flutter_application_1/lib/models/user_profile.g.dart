// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      profileId: fields[0] as String,
      ageGroup: fields[1] as AgeGroup,
      hasHypertension: fields[2] as bool,
      hasDiabetes: fields[3] as bool,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.ageGroup)
      ..writeByte(2)
      ..write(obj.hasHypertension)
      ..writeByte(3)
      ..write(obj.hasDiabetes)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgeGroupAdapter extends TypeAdapter<AgeGroup> {
  @override
  final int typeId = 1;

  @override
  AgeGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgeGroup.under40;
      case 1:
        return AgeGroup.from40to59;
      case 2:
        return AgeGroup.above60;
      default:
        return AgeGroup.under40;
    }
  }

  @override
  void write(BinaryWriter writer, AgeGroup obj) {
    switch (obj) {
      case AgeGroup.under40:
        writer.writeByte(0);
        break;
      case AgeGroup.from40to59:
        writer.writeByte(1);
        break;
      case AgeGroup.above60:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgeGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
