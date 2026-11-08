import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/presentation/providers/auth_state_provider.dart';
import 'token_storage.dart';

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
      return ApiException(data['message'].toString(), statusCode, data['details']);
    }
    if (statusCode == 401) {
      return ApiException('Session expired or unauthorized. Please log in again.', statusCode);
    }
    if (statusCode == 403) {
      return ApiException('You do not have permission to perform this action.', statusCode);
    }
    if (statusCode == 404) {
      return ApiException('The requested resource was not found.', statusCode);
    }
    if (statusCode == 429) {
      return ApiException('Too many attempts. Try again in 5 minutes.', statusCode);
    }
    return ApiException('Server error ($statusCode). Please try again.', statusCode);
  }
  if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
    return ApiException('Connection timed out. Please check your network.');
  }
  if (error.type == DioExceptionType.connectionError) {
    return ApiException('Could not connect to the server. Please check your connection.');
  }
  return ApiException(error.message ?? 'An unexpected network error occurred.');
}

/// Attaches `Authorization: Bearer <token>` to outgoing HTTP requests and intercepts 401 Unauthorized.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
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
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/forgot-password')) {
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
  final TokenStorage tokenStorage;
  final void Function()? onSessionExpired;

  /// Global adapter override for automated test harnesses.
  static HttpClientAdapter? testAdapter;
  static void Function()? onGlobalSessionExpired;

  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5000/api';
        }
      } catch (_) {}
    }
    return 'http://localhost:5000/api';
  }

  ApiClient({
    String? baseUrl,
    TokenStorage? tokenStorage,
    Dio? customDio,
    this.onSessionExpired,
  })  : tokenStorage = tokenStorage ?? TokenStorage(),
        dio = customDio ??
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
        onSessionExpired: () => (onSessionExpired ?? onGlobalSessionExpired)?.call(),
      ),
    );
    if (testAdapter != null) {
      dio.httpClientAdapter = testAdapter!;
    }
  }

  Future<Response<T>> _directFetch<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?options?.headers,
    };
    final token = tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final reqOptions = RequestOptions(
      path: path,
      method: method,
      baseUrl: dio.options.baseUrl,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );

    final resBody = await testAdapter!.fetch(reqOptions, null, null);
    dynamic bodyData;
    try {
      final str = await utf8.decodeStream(resBody.stream);
      if (str.isNotEmpty) {
        bodyData = jsonDecode(str);
      }
    } catch (_) {}

    final response = Response<T>(
      data: bodyData as T,
      statusCode: resBody.statusCode,
      headers: Headers.fromMap(resBody.headers),
      requestOptions: reqOptions,
    );

    if (resBody.statusCode >= 200 && resBody.statusCode < 300) {
      return response;
    }

    if (resBody.statusCode == 401 &&
        !path.contains('/auth/login') &&
        !path.contains('/auth/forgot-password')) {
      await tokenStorage.clearAll();
      (onSessionExpired ?? onGlobalSessionExpired)?.call();
    }

    final dioException = DioException(
      requestOptions: reqOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
    throw mapDioException(dioException);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (testAdapter != null) {
      return _directFetch<T>('GET', path, queryParameters: queryParameters, options: options);
    }
    try {
      return await dio.get<T>(path, queryParameters: queryParameters, options: options);
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
    if (testAdapter != null) {
      return _directFetch<T>('POST', path, data: data, queryParameters: queryParameters, options: options);
    }
    try {
      return await dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
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
    if (testAdapter != null) {
      return _directFetch<T>('PUT', path, data: data, queryParameters: queryParameters, options: options);
    }
    try {
      return await dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
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
    if (testAdapter != null) {
      return _directFetch<T>('DELETE', path, data: data, queryParameters: queryParameters, options: options);
    }
    try {
      return await dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
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
    if (testAdapter != null) {
      return _directFetch<T>('PATCH', path, data: data, queryParameters: queryParameters, options: options);
    }
    try {
      return await dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: storage,
    onSessionExpired: () {
      ref.read(authStateProvider.notifier).setUser(null);
    },
  );
});
