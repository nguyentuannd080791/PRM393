import '../config/api_config.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';

import '../storage/session_storage.dart';

/// Exception thrown on REST API failure.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, [this.statusCode, this.details]);

  @override
  String toString() => message;
}

/// Transforms DioException into user-friendly [ApiException].
ApiException mapDioException(DioException error) {
  if (error.response != null) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return ApiException(
        data['message'].toString(),
        statusCode,
        data['details'],
      );
    }
    if (statusCode == 401) {
      return ApiException(
        'Session expired or unauthorized. Please log in again.',
        statusCode,
      );
    }
    if (statusCode == 403) {
      return ApiException(
        'You do not have permission to perform this action.',
        statusCode,
      );
    }
    if (statusCode == 404) {
      return ApiException('The requested resource was not found.', statusCode);
    }
    if (statusCode == 429) {
      return ApiException(
        'Too many attempts. Try again in 5 minutes.',
        statusCode,
      );
    }
    return ApiException(
      'Server error ($statusCode). Please try again.',
      statusCode,
    );
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return ApiException('Unable to connect. Please try again.');
  }
  if (error.type == DioExceptionType.connectionError) {
    return ApiException('Unable to connect. Please try again.');
  }
  return ApiException(error.message ?? 'An unexpected network error occurred.');
}

/// Attaches `Authorization: Bearer <token>` to outgoing HTTP requests and intercepts 401 Unauthorized.
class AuthInterceptor extends Interceptor {
  final SessionStorage _tokenStorage;
  final void Function()? onSessionExpired;

  AuthInterceptor(this._tokenStorage, {this.onSessionExpired});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login')) {
      try {
        await _tokenStorage.clearAll();
      } catch (_) {}
      try {
        onSessionExpired?.call();
      } catch (_) {}
    }
    handler.next(err);
  }
}

/// Centralized Dio REST API Client.
class ApiClient {
  final Dio dio;
  final SessionStorage tokenStorage;
  final void Function()? onSessionExpired;

  static void Function()? onGlobalSessionExpired;

  static String get defaultBaseUrl => ApiConfig.baseUrl;

  ApiClient({
    String? baseUrl,
    SessionStorage? tokenStorage,
    Dio? customDio,
    this.onSessionExpired,
  }) : tokenStorage = tokenStorage ?? SessionStorage(),
       dio =
           customDio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? defaultBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    dio.interceptors.add(
      AuthInterceptor(
        this.tokenStorage,
        onSessionExpired: () =>
            (onSessionExpired ?? onGlobalSessionExpired)?.call(),
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(sessionStorageProvider);
  return ApiClient(
    tokenStorage: storage,
    onSessionExpired: () {
      ref.read(authStateProvider.notifier).setUser(null);
    },
  );
});
