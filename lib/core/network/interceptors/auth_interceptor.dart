import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      AppLogger.log('Auth token added to request', 'Auth');
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      AppLogger.log('Unauthorized - Token may be expired', 'Auth');
      // Could trigger token refresh or logout here
    }
    
    handler.next(err);
  }
}


