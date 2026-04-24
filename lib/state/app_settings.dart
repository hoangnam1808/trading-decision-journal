import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { en, vi }

extension AppLangX on AppLang {
  String get code => this == AppLang.en ? 'en' : 'vi';
  String get label => this == AppLang.en ? 'English' : 'Tiếng Việt';
  Locale get locale => Locale(code);
}

class AppSettings extends ChangeNotifier {
  static const _kLangKey = 'app_lang';
  static const _kThemeModeKey = 'app_theme_mode';
  static const _kCashPerRKey = 'cash_per_r';

  AppLang lang = AppLang.en;
  ThemeMode themeMode = ThemeMode.system;
  double cashPerR = 100.0;

  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final langCode = prefs.getString(_kLangKey);
    if (langCode == 'vi') {
      lang = AppLang.vi;
    } else {
      lang = AppLang.en;
    }

    final themeCode = prefs.getString(_kThemeModeKey);
    switch (themeCode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    cashPerR = prefs.getDouble(_kCashPerRKey) ?? 100.0;

    loaded = true;
    notifyListeners();
  }

  Future<void> setLang(AppLang value) async {
    lang = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, value.code);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final code = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kThemeModeKey, code);
  }

  Future<void> setCashPerR(double value) async {
    if (value <= 0) return;

    cashPerR = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kCashPerRKey, value);
  }
}