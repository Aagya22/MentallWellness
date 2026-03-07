import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());

    // Auto retry on network failures
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // Get
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // post
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // put
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // del
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // patch
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // Upload file
  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: formData,
      options: options ?? Options(contentType: 'multipart/form-data'),
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _journalAccessTokenKey = 'journal_access_token';
  static const String _journalAccessTokenExpiresAtKey =
      'journal_access_token_expires_at_ms';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header only for public auth endpoints.
    final isPublicAuthEndpoint =
        options.path == ApiEndpoints.userLogin ||
        options.path == ApiEndpoints.userRegister;

    if (!isPublicAuthEndpoint) {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Attach journal unlock token only for journal endpoints.
    if (options.path.startsWith(ApiEndpoints.journals)) {
      final expiresAtRaw = await _storage.read(
        key: _journalAccessTokenExpiresAtKey,
      );
      final token = await _storage.read(key: _journalAccessTokenKey);

      final expiresAtMs = expiresAtRaw != null
          ? int.tryParse(expiresAtRaw)
          : null;
      final isExpired =
          expiresAtMs != null &&
          DateTime.now().millisecondsSinceEpoch >= expiresAtMs;

      if (isExpired) {
        await Future.wait([
          _storage.delete(key: _journalAccessTokenKey),
          _storage.delete(key: _journalAccessTokenExpiresAtKey),
        ]);
      } else if (token != null && token.isNotEmpty) {
        options.headers['x-journal-access-token'] = token;
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Journal unlock token expired/invalid.
    if (status == 403 &&
        err.response?.data?['code'] == 'JOURNAL_PASSCODE_INVALID') {
      _storage.delete(key: _journalAccessTokenKey);
      _storage.delete(key: _journalAccessTokenExpiresAtKey);
    }

    final isJournalPasscodeEndpoint =
        path == ApiEndpoints.journalPasscode ||
        path == ApiEndpoints.journalPasscodeVerify;
    if (status == 401 && !isJournalPasscodeEndpoint) {
      _storage.delete(key: _tokenKey);
      _storage.delete(key: _journalAccessTokenKey);
      _storage.delete(key: _journalAccessTokenExpiresAtKey);
    }

    handler.next(err);
  }
}
