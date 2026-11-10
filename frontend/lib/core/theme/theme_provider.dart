import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/storage/preferences_provider.dart';

/// Manages app ThemeMode (ThemeMode.light vs ThemeMode.dark).
/// Default mode at launch is ThemeMode.light per R2.1.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String prefKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) {
      return ThemeMode.light;
    }

    final savedMode = prefs.getString(prefKey);
    if (savedMode == 'dark') {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  /// Sets a specific ThemeMode and persists choice to SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      await prefs.setString(prefKey, mode == ThemeMode.light ? 'light' : 'dark');
    }
  }

  /// Toggles between Dark and Light mode and persists the updated setting.
  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

/// Riverpod Provider exposing the current ThemeMode.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Convenience Provider to watch whether the app is currently in Dark Mode.
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});
