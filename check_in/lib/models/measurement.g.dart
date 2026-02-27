// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 0;

  @override
  Measurement read(BinaryReader reader) {
    return Measurement(
      id: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      heartRate: reader.readDouble(),
      afPrediction: reader.readInt(),
      confidence: reader.readInt(),
      rhythm: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeDouble(obj.heartRate);
    writer.writeInt(obj.afPrediction);
    writer.writeInt(obj.confidence);
    writer.writeString(obj.rhythm);
  }
}