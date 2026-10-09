import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/hive_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final HiveStorageService _storage;
  final Dio _dio;
  final VoidCallback? onSessionExpired;
  bool _isRefreshing = false;

  AuthInterceptor({
    required HiveStorageService storage,
    required Dio dio,
    this.onSessionExpired,
  })  : _storage = storage,
        _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject Bearer token if available and not a public auth endpoint
    final accessToken = _storage.getAccessToken();
    final isAuthEndpoint = options.path.contains('/auth/login') || options.path.contains('/auth/refresh');

    if (accessToken != null && !isAuthEndpoint) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    options.headers['Content-Type'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;

    // Check if error is 401 Unauthorized and not already refreshing / logging in
    if (response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/login') && !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;

        try {
          // Attempt to refresh the access token using DummyJSON refresh endpoint
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: {'Content-Type': 'application/json'},
            ),
          );

          final refreshResponse = await refreshDio.post(
            ApiConstants.refresh,
            data: {
              'refreshToken': refreshToken,
              'expiresInMins': 60,
            },
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final newAccessToken = refreshResponse.data['accessToken'] as String? ?? refreshResponse.data['token'] as String?;
            final newRefreshToken = refreshResponse.data['refreshToken'] as String? ?? refreshToken;

            if (newAccessToken != null) {
              await _storage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              _isRefreshing = false;

              // Retry original request with new token
              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (refreshErr) {
          debugPrint('Token refresh failed: $refreshErr');
        } finally {
          _isRefreshing = false;
        }

        // If refresh failed, clear session and notify app
        await _storage.clearAuthData();
        onSessionExpired?.call();
      }
    }

    return handler.next(err);
  }
}
