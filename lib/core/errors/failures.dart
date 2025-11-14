import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network connection failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

/// Rate limit exceeded failures
class RateLimitFailure extends Failure {
  final Duration retryAfter;

  const RateLimitFailure({
    required super.message,
    required this.retryAfter,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, retryAfter];
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// API key invalid or missing
class ApiKeyFailure extends Failure {
  const ApiKeyFailure({
    required super.message,
    super.code,
  });
}

/// WebSocket connection failures
class WebSocketFailure extends Failure {
  const WebSocketFailure({
    required super.message,
    super.code,
  });
}

/// Data parsing failures
class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    super.code,
  });
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}
