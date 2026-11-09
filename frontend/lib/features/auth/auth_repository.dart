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
    required String email,
    String? phone,
    required String password,
    required DateTime birthday,
    required String gender,
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
        'birthday': birthday.toIso8601String().split('T').first,
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
      if (e is ApiException && e.statusCode == 401) {
        await _tokenStorage.clearAll();
        return null;
      }
      return _tokenStorage.getUser();
    }
  }

  Future<String> forgotPassword(
    String identifier, [
    String newPassword = '',
  ]) async {
    final response = await _apiClient.post(
      '/auth/forgot-password',
      data: {'identifier': identifier, 'new_password': newPassword},
    );
    return response.data['message'] as String? ??
        'Password updated successfully';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(sessionStorageProvider);
  return AuthRepository(client, storage);
});
