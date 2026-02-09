// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionRecordAdapter extends TypeAdapter<SessionRecord> {
  @override
  final int typeId = 4;

  @override
  SessionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionRecord(
      sessionId: fields[0] as String,
      timestamp: fields[1] as DateTime,
      afResult: fields[2] as AfResult,
      confidence: fields[3] as int,
      signalQuality: fields[4] as int,
      heartRateBpm: fields[5] as double,
      acceptedWindows: fields[10] as int,
      totalWindows: fields[11] as int,
      flags: (fields[12] as List).cast<String>(),
      spo2: fields[6] as double?,
      spo2Confidence: fields[7] as int?,
      ecgRmssdMs: fields[8] as double?,
      ppgRmssdMs: fields[9] as double?,
      deviceId: fields[13] as String?,
      firmwareVersion: fields[14] as String?,
      durationSec: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.afResult)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.signalQuality)
      ..writeByte(5)
      ..write(obj.heartRateBpm)
      ..writeByte(6)
      ..write(obj.spo2)
      ..writeByte(7)
      ..write(obj.spo2Confidence)
      ..writeByte(8)
      ..write(obj.ecgRmssdMs)
      ..writeByte(9)
      ..write(obj.ppgRmssdMs)
      ..writeByte(10)
      ..write(obj.acceptedWindows)
      ..writeByte(11)
      ..write(obj.totalWindows)
      ..writeByte(12)
      ..write(obj.flags)
      ..writeByte(13)
      ..write(obj.deviceId)
      ..writeByte(14)
      ..write(obj.firmwareVersion)
      ..writeByte(15)
      ..write(obj.durationSec);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AfResultAdapter extends TypeAdapter<AfResult> {
  @override
  final int typeId = 3;

  @override
  AfResult read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AfResult.ok;
      case 1:
        return AfResult.notOk;
      case 2:
        return AfResult.inconclusive;
      default:
        return AfResult.ok;
    }
  }

  @override
  void write(BinaryWriter writer, AfResult obj) {
    switch (obj) {
      case AfResult.ok:
        writer.writeByte(0);
        break;
      case AfResult.notOk:
        writer.writeByte(1);
        break;
      case AfResult.inconclusive:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AfResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
