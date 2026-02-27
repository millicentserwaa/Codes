import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings extends ChangeNotifier {
  static const _box = 'app_settings';

  double    _fontScale        = 1.0;
  ThemeMode _theme            = ThemeMode.light;
  bool      _reminderEnabled  = false;
  TimeOfDay _reminderTime     = const TimeOfDay(hour: 9, minute: 0);

  double    get fontScale       => _fontScale;
  ThemeMode get themeMode       => _theme;
  bool      get isDark          => _theme == ThemeMode.dark;
  bool      get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime    => _reminderTime;

  static Future<void> initBox() async {
    await Hive.openBox(_box);
  }

  Future<void> load() async {
    final box = Hive.box(_box);
    _fontScale       = box.get('font_scale',        defaultValue: 1.0);
    final t          = box.get('theme_mode',         defaultValue: 'light');
    _theme           = t == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _reminderEnabled = box.get('reminder_enabled',   defaultValue: false);
    final rh         = box.get('reminder_hour',      defaultValue: 9);
    final rm         = box.get('reminder_minute',    defaultValue: 0);
    _reminderTime    = TimeOfDay(hour: rh, minute: rm);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await Hive.box(_box).put('font_scale', scale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _theme = mode;
    await Hive.box(_box).put('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await Hive.box(_box).put('reminder_enabled', enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await Hive.box(_box).put('reminder_hour',   time.hour);
    await Hive.box(_box).put('reminder_minute', time.minute);
    notifyListeners();
  }
}