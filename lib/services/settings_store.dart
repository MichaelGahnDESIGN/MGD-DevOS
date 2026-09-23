import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistiert nur unkritische App-Einstellungen (Theme, Akzentfarbe,
/// Projekt-Root-Pfad, Onboarding-Status) über [SharedPreferences].
///
/// Es werden hier bewusst keine Zugangsdaten oder Secrets gespeichert.
/// Echte Zugänge gehören in den OS-Schlüsselbund (siehe Restliste in der
/// Projekt-Übergabe) und sind für diese erste Version noch nicht
/// implementiert.
class SettingsStore {
  static const _keyOnboardingDone = 'onboarding_done_v1';
  static const _keyThemeMode = 'theme_mode_v1';
  static const _keyAccentColor = 'accent_color_v1';
  static const _keyProjectsRoot = 'projects_root_v1';
  static const _keyLocale = 'locale_v1';

  static const Color defaultAccentColor = Color(0xFFCD1616);

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, value);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<Color> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_keyAccentColor);
    return value == null ? defaultAccentColor : Color(value);
  }

  Future<void> setAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, color.toARGB32());
  }

  Future<String?> getProjectsRoot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProjectsRoot);
  }

  Future<void> setProjectsRoot(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProjectsRoot, path);
  }

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? 'de';
  }

  Future<void> setLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, localeCode);
  }
}
