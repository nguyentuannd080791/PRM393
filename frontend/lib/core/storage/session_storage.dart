import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import 'preferences_provider.dart';

/// Persistent storage for JWT authentication tokens and current user snapshot.
class SessionStorage {
  final SharedPreferences? _prefs;
  final Map<String, String> _memoryFallback = {};
  bool _userCleared = false;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  /// Optional hook for automated test harnesses.
  static UserModel? Function()? testUserFallback;

  SessionStorage([this._prefs]);

  Future<void> saveToken(String token) async {
    if (_prefs != null) {
      await _prefs.setString(_tokenKey, token);
    } else {
      _memoryFallback[_tokenKey] = token;
    }
  }

  String? getToken() {
    if (_prefs != null) {
      return _prefs.getString(_tokenKey);
    }
    return _memoryFallback[_tokenKey];
  }

  Future<void> clearToken() async {
    if (_prefs != null) {
      await _prefs.remove(_tokenKey);
    } else {
      _memoryFallback.remove(_tokenKey);
    }
  }

  Future<void> saveUser(UserModel user) async {
    _userCleared = false;
    final str = jsonEncode(user.toJson());
    if (_prefs != null) {
      await _prefs.setString(_userKey, str);
    } else {
      _memoryFallback[_userKey] = str;
    }
  }

  UserModel? getUser() {
    if (_userCleared) return null;
    final userStr = _prefs != null
        ? _prefs.getString(_userKey)
        : _memoryFallback[_userKey];
    if (userStr != null && userStr.isNotEmpty) {
      try {
        final json = jsonDecode(userStr) as Map<String, dynamic>;
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return testUserFallback?.call();
  }

  Future<void> clearUser() async {
    _userCleared = true;
    testUserFallback = null;
    if (_prefs != null) {
      await _prefs.remove(_userKey);
    } else {
      _memoryFallback.remove(_userKey);
    }
  }

  Future<void> clearAll() async {
    _userCleared = true;
    testUserFallback = null;
    await clearToken();
    await clearUser();
  }
}

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SessionStorage(prefs);
});
