/// Base exception class
class AppException implements Exception {
  final String message;
  final int? code;

  AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Server exception
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
  });
}

/// Network exception
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
  });
}

/// Rate limit exception
class RateLimitException extends AppException {
  final Duration retryAfter;

  RateLimitException({
    required super.message,
    required this.retryAfter,
    super.code,
  });
}

/// Cache exception
class CacheException extends AppException {
  CacheException({
    required super.message,
    super.code,
  });
}

/// Authentication exception
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
  });
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code,
  });
}

/// API key exception
class ApiKeyException extends AppException {
  ApiKeyException({
    required super.message,
    super.code,
  });
}

/// WebSocket exception
class WebSocketException extends AppException {
  WebSocketException({
    required super.message,
    super.code,
  });
}

/// Parsing exception
class ParsingException extends AppException {
  ParsingException({
    required super.message,
    super.code,
  });
}

/// Timeout exception
class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.code,
  });
}
