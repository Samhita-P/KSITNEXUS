import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  
  static Future<AppThemeMode> getThemeMode() async {
    // Force light mode - ignore stored preferences
    // final prefs = await SharedPreferences.getInstance();
    // final themeString = prefs.getString(_themeKey) ?? 'system';
    // return AppThemeMode.values.firstWhere(
    //   (mode) => mode.name == themeString,
    //   orElse: () => AppThemeMode.system,
    // );
    return AppThemeMode.light; // Always return light mode
  }
  
  static Future<void> setThemeMode(AppThemeMode mode) async {
    // Disabled - theme changes are ignored, always light mode
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(_themeKey, mode.name);
    // Do nothing - theme is always light
  }
  
  static ThemeMode getThemeModeForMaterial(AppThemeMode mode) {
    // Force light mode regardless of input
    // switch (mode) {
    //   case AppThemeMode.light:
    //     return ThemeMode.light;
    //   case AppThemeMode.dark:
    //     return ThemeMode.dark;
    //   case AppThemeMode.system:
    //     return ThemeMode.system;
    // }
    return ThemeMode.light; // Always return light mode
  }
}

















