import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  static const String _prefsKey = 'app_theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_prefsKey);

    if (savedValue == 'dark') {
      value = ThemeMode.dark;
      return;
    }

    value = ThemeMode.light;
  }

  Future<void> toggle() async {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value == ThemeMode.dark ? 'dark' : 'light');
  }
}

final ThemeController appThemeController = ThemeController();
