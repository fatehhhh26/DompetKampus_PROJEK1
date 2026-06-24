import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadTheme();
  }

  static const _darkModeKey = 'is_dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void _loadTheme() {
    if (!Hive.isBoxOpen(LocalStorageService.settingsBox)) return;

    final box = Hive.box(LocalStorageService.settingsBox);
    _isDarkMode = box.get(_darkModeKey, defaultValue: false) == true;
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;

    if (Hive.isBoxOpen(LocalStorageService.settingsBox)) {
      final box = Hive.box(LocalStorageService.settingsBox);
      await box.put(_darkModeKey, value);
    }

    notifyListeners();
  }
}
