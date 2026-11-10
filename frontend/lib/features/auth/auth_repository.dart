import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SessionStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<UserModel> register({
    required String fullName,
    String? email,
    required String phone,
    required String password,
    DateTime? birthday,
    String? gender,
    String? city,
    String? workplace,
    String? bio,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'birthday': birthday?.toIso8601String().split('T').first,
        'gender': gender,
        'city': city,
        'workplace': workplace,
        'bio': bio,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveUser(user);
    return user;
  }

  Future<UserModel> login(String identifier, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Clear token locally even if server is unreachable
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  Future<UserModel?> getMe() async {
    final token = _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get('/auth/me');
      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _tokenStorage.saveUser(user);
      return user;
    } catch (e) {
      // 401: bad/expired token. 404: the account no longer exists. Either way the saved session is useless.
      bool invalidSession(int? code) => code == 401 || code == 404;
      if ((e is ApiException && invalidSession(e.statusCode)) ||
          (e is DioException && invalidSession(e.response?.statusCode))) {
        await _tokenStorage.clearAll();
        return null;
      }
      return _tokenStorage.getUser();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    // The server revokes every older token, so keep this device signed in with the fresh one.
    final data = response.data['data'];
    final token = data is Map ? data['token'] as String? : null;
    if (token != null) await _tokenStorage.saveToken(token);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(sessionStorageProvider);
  return AuthRepository(client, storage);
});
