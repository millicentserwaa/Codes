import 'package:hive_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  final double fontScale; // 1.0 = normal, 1.2 = large, 1.4 = extra large

  @HiveField(1)
  final bool ttsEnabled;

  @HiveField(2)
  final bool reminderEnabled;

  @HiveField(3)
  final int reminderHour; // 24hr format

  @HiveField(4)
  final int reminderMinute;

  @HiveField(5)
  final bool isDarkMode;

  AppSettings({
    this.fontScale = 1.0,
    this.ttsEnabled = true,
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.isDarkMode = false,
  });

  // Font scale label for UI display
  String get fontScaleLabel {
    if (fontScale <= 1.0) return 'Normal';
    if (fontScale <= 1.2) return 'Large';
    if (fontScale <= 1.4) return 'Extra Large';
    return 'Extra Large';
  }

  // Copy with updated fields
  AppSettings copyWith({
    double? fontScale,
    bool? ttsEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isDarkMode,
  }) {
    return AppSettings(
      fontScale: fontScale ?? this.fontScale,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}