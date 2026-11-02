import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences)
    : _isDarkMode = _preferences.getBool('nutrimarket_theme_dark') ?? false;

  final SharedPreferences _preferences;
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  Future<void> toggle() async {
    final next = !_isDarkMode;
    await _preferences.setBool('nutrimarket_theme_dark', next);
    _isDarkMode = next;
    notifyListeners();
  }
}
