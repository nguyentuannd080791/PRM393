import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for accessing [SharedPreferences].
///
/// In production, overridden in the root [ProviderScope] during bootstrapping in `main.dart`.
/// In test environments, defaults to `null` so test harnesses do not throw unless explicitly needed.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
