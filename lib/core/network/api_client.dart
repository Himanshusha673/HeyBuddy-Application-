import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hey_buddy/core/network/interceptors/logging_interceptor.dart';
import '../config/constants/app_constants.dart';
import '../exceptions/network_exception.dart';

import '../utils/logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;

  ApiClient({Dio? dio, String? baseUrl})
    : baseUrl = baseUrl ?? AppConstants.baseUrl {
    _dio = dio ?? Dio();
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.timeoutDuration,
      receiveTimeout: AppConstants.timeoutDuration,
      sendTimeout: AppConstants.timeoutDuration,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('GET request failed', e, stackTrace);
      throw NetworkException(
        message: 'Request failed: ${e.toString()}',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('POST request failed', e, stackTrace);
      throw NetworkException(
        message: 'Request failed: ${e.toString()}',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('PUT request failed', e, stackTrace);
      throw NetworkException(
        message: 'Request failed: ${e.toString()}',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('DELETE request failed', e, stackTrace);
      throw NetworkException(
        message: 'Request failed: ${e.toString()}',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  dynamic _handleResponse(Response response) {
    AppLogger.log('Response: ${response.statusCode}', 'API');

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    } else {
      throw NetworkException(
        message: 'Unexpected status code: ${response.statusCode}',
        statusCode: response.statusCode,
        type: NetworkExceptionType.unknown,
      );
    }
  }

  NetworkException _handleDioError(DioException error) {
    AppLogger.error('Dio Error', error, error.stackTrace);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();

      case DioExceptionType.connectionError:
        return NetworkException.noInternet();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return NetworkException.unauthorized();
        } else if (statusCode == 404) {
          return NetworkException.notFound();
        } else if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500) {
          return NetworkException.badRequest(
            error.response?.data?['message']?.toString(),
          );
        } else {
          return NetworkException.serverError(statusCode);
        }

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          type: NetworkExceptionType.unknown,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Bad certificate',
          type: NetworkExceptionType.unknown,
        );

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return NetworkException.noInternet();
        }
        return NetworkException(
          message: error.message ?? 'Unknown error occurred',
          type: NetworkExceptionType.unknown,
        );
    }
  }

  void dispose() {
    _dio.close();
  }
}
