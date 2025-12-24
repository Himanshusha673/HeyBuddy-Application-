class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final NetworkExceptionType type;
  final dynamic data;

  NetworkException({
    required this.message,
    this.statusCode,
    this.type = NetworkExceptionType.unknown,
    this.data,
  });

  @override
  String toString() => 'NetworkException: $message (${statusCode ?? 'N/A'})';

  factory NetworkException.noInternet() {
    return NetworkException(
      message: 'No internet connection. Please check your network.',
      type: NetworkExceptionType.noInternet,
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      message: 'Request timeout. Please try again.',
      type: NetworkExceptionType.timeout,
    );
  }

  factory NetworkException.serverError([int? statusCode]) {
    return NetworkException(
      message: 'Server error occurred. Please try again later.',
      statusCode: statusCode,
      type: NetworkExceptionType.serverError,
    );
  }

  factory NetworkException.notFound() {
    return NetworkException(
      message: 'Resource not found.',
      statusCode: 404,
      type: NetworkExceptionType.notFound,
    );
  }

  factory NetworkException.unauthorized() {
    return NetworkException(
      message: 'Unauthorized access.',
      statusCode: 401,
      type: NetworkExceptionType.unauthorized,
    );
  }

  factory NetworkException.badRequest([String? message]) {
    return NetworkException(
      message: message ?? 'Bad request.',
      statusCode: 400,
      type: NetworkExceptionType.badRequest,
    );
  }

  factory NetworkException.parseError() {
    return NetworkException(
      message: 'Failed to parse response data.',
      type: NetworkExceptionType.parseError,
    );
  }
}

enum NetworkExceptionType {
  noInternet,
  timeout,
  serverError,
  notFound,
  unauthorized,
  badRequest,
  parseError,
  unknown,
}