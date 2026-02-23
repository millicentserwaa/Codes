import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings extends ChangeNotifier {
  static const _box = 'app_settings';

  double _fontScale  = 1.0;   // 0.85 | 1.0 | 1.2 | 1.4
  ThemeMode _theme   = ThemeMode.light;

  double    get fontScale => _fontScale;
  ThemeMode get themeMode => _theme;
  bool      get isDark    => _theme == ThemeMode.dark;

  static Future<void> initBox() async {
    await Hive.openBox(_box);
  }

  Future<void> load() async {
    final box = Hive.box(_box);
    _fontScale = box.get('font_scale',  defaultValue: 1.0);
    final t    = box.get('theme_mode',  defaultValue: 'light');
    _theme     = t == 'dark' ? ThemeMode.dark : ThemeMode.light;
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
}
