import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/storage/preferences_provider.dart';

/// Manages app ThemeMode (ThemeMode.dark vs ThemeMode.light).
/// Strictly satisfies BR-21: Default mode at launch is ThemeMode.dark.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String prefKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) {
      // Fallback for tests or un-overridden scopes (BR-21 dark default)
      return ThemeMode.dark;
    }

    final savedMode = prefs.getString(prefKey);
    if (savedMode == 'light') {
      return ThemeMode.light;
    }
    // BR-21: Mandatory default is dark mode!
    return ThemeMode.dark;
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
