import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/storage/preferences_provider.dart';

/// Keeps a fixed light appearance, including when an older dark preference exists.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String prefKey = 'theme_mode';

  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  /// Preserves the existing API while enforcing the fixed light appearance.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeMode.light;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      await prefs.setString(prefKey, 'light');
    }
  }

  /// Legacy callers also retain the fixed light appearance.
  Future<void> toggleTheme() async {
    await setThemeMode(ThemeMode.light);
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
