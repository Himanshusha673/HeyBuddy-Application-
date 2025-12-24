import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../exceptions/network_exception.dart';
import '../../utils/logger.dart';

class ConnectivityInterceptor extends Interceptor {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        AppLogger.log('No internet connection', 'Connectivity');
        return handler.reject(
          DioException(
            requestOptions: options,
            error: NetworkException.noInternet(),
            type: DioExceptionType.connectionError,
          ),
        );
      }
      
      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }
}
