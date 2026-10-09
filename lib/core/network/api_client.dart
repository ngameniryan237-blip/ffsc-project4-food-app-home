import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../storage/hive_storage.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';

class ApiClient {
  late final Dio dio;
  final HiveStorageService _storage;
  final NetworkInfo _networkInfo;

  ApiClient({
    HiveStorageService? storage,
    NetworkInfo? networkInfo,
    VoidCallback? onSessionExpired,
    Dio? customDio,
  })  : _storage = storage ?? HiveStorageService(),
        _networkInfo = networkInfo ?? NetworkInfoImpl() {
    if (customDio != null) {
      dio = customDio;
    } else {
      dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      dio.interceptors.add(
        AuthInterceptor(
          storage: _storage,
          dio: dio,
          onSessionExpired: onSessionExpired,
        ),
      );

      if (kDebugMode) {
        dio.interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            requestHeader: true,
            responseHeader: false,
            error: true,
          ),
        );
      }
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      throw const NetworkException();
    }

    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      throw const NetworkException();
    }

    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Never _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException(message: 'Connection timeout. Please check your network.');
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    String errorMessage = 'A server error occurred. Please try again.';

    if (responseData is Map && responseData.containsKey('message')) {
      errorMessage = responseData['message'].toString();
    } else if (e.message != null && e.message!.isNotEmpty) {
      errorMessage = e.message!;
    }

    if (statusCode == 401 || statusCode == 403) {
      throw AuthException(message: errorMessage, statusCode: statusCode);
    }

    throw ServerException(message: errorMessage, statusCode: statusCode);
  }
}
