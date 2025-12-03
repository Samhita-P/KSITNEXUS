import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light) {
    // Force light mode - don't load from storage
    // _loadThemeMode();
    state = AppThemeMode.light;
  }

  Future<void> _loadThemeMode() async {
    // Disabled - always return light mode
    // final mode = await ThemeService.getThemeMode();
    // state = mode;
    state = AppThemeMode.light;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    // Disabled - theme changes are ignored, always light mode
    // await ThemeService.setThemeMode(mode);
    // state = mode;
    // Force light mode regardless of requested mode
    state = AppThemeMode.light;
  }
}

// Theme provider is handled by MaterialApp.router's themeMode
// No need for separate theme provider since MaterialApp handles it

