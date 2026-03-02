// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    return AppSettings(
      fontScale: reader.readDouble(),
      ttsEnabled: reader.readBool(),
      reminderEnabled: reader.readBool(),
      reminderHour: reader.readInt(),
      reminderMinute: reader.readInt(),
      isDarkMode: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeDouble(obj.fontScale);
    writer.writeBool(obj.ttsEnabled);
    writer.writeBool(obj.reminderEnabled);
    writer.writeInt(obj.reminderHour);
    writer.writeInt(obj.reminderMinute);
    writer.writeBool(obj.isDarkMode);
  }
}