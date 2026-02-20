import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  bool _isVerified = false;
  bool _isAdmin = false;
  bool _isInitialized = false;
  ThemeMode _themeMode = ThemeMode.dark;
  int _mainIndex = 0;

  bool get isVerified => _isVerified;
  bool get isAdmin => _isAdmin;
  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  int get mainIndex => _mainIndex;

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isVerified = prefs.getBool('is_verified') ?? false;
    _isAdmin = prefs.getBool('is_admin') ?? false;

    final isDark = prefs.getBool('is_dark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setVerified(bool value) async {
    _isVerified = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_verified', value);
    notifyListeners();
  }

  Future<void> setAdmin(bool value) async {
    _isAdmin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', value);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> logout() async {
    _isVerified = false;
    _isAdmin = false;
    _mainIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_verified', false);
    await prefs.setBool('is_admin', false);
    notifyListeners();
  }

  void setMainIndex(int index) {
    _mainIndex = index;
    notifyListeners();
  }
}
