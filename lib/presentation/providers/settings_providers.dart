import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:task_time/main.dart'; // For settingsBoxName

const String _themeModeKey = 'theme_mode';

// Enum for ThemeMode to be stored as string or index
// Using string for readability in Hive, though index is more efficient.
// Flutter's ThemeMode enum itself can be used directly.

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Box _settingsBox;

  ThemeModeNotifier(this._settingsBox) : super(_loadThemeMode(_settingsBox));

  static ThemeMode _loadThemeMode(Box box) {
    final String? themeModeStr = box.get(_themeModeKey) as String?;
    switch (themeModeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String themeModeStr;
    switch (mode) {
      case ThemeMode.light:
        themeModeStr = 'light';
        break;
      case ThemeMode.dark:
        themeModeStr = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeModeStr = 'system';
        break;
    }
    await _settingsBox.put(_themeModeKey, themeModeStr);
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settingsBox = Hive.box(settingsBoxName);
  return ThemeModeNotifier(settingsBox);
});
