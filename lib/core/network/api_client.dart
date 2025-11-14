import 'package:dio/dio.dart';
import 'package:fin_pulse/core/constants/api_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:logger/logger.dart';

/// Network client with built-in retry logic and error handling
class ApiClient {
  final Dio _dio;
  final Logger _logger = Logger();

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConstants.connectionTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                validateStatus: (status) => status != null && status < 500,
              ),
            ) {
    _setupInterceptors();
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST[${options.method}] => ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
            error: error.error,
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Execute GET request with retry logic
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    int maxRetries = 3,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: timeout,
        ),
      ),
      maxRetries: maxRetries,
    );
  }

  /// Execute POST request with retry logic
  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    int maxRetries = 3,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: timeout,
        ),
      ),
      maxRetries: maxRetries,
    );
  }

  /// Execute PUT request with retry logic
  Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    int maxRetries = 3,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: timeout,
        ),
      ),
      maxRetries: maxRetries,
    );
  }

  /// Execute DELETE request with retry logic
  Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    int maxRetries = 3,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: timeout,
        ),
      ),
      maxRetries: maxRetries,
    );
  }

  /// Execute request with exponential backoff retry
  Future<Response> _executeWithRetry(
    Future<Response> Function() request, {
    required int maxRetries,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        final response = await request();
        _handleResponse(response);
        return response;
      } on DioException catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          _logger.e('Max retries ($maxRetries) exceeded');
          throw _mapDioException(e);
        }

        if (!_shouldRetry(e)) {
          throw _mapDioException(e);
        }

        final backoffDuration = _calculateBackoff(attempt);
        _logger.w(
          'Request failed. Retrying in ${backoffDuration.inSeconds}s... '
          '(Attempt $attempt/$maxRetries)',
        );

        await Future.delayed(backoffDuration);
      } catch (e) {
        _logger.e('Unexpected error during request', error: e);
        rethrow;
      }
    }
  }

  /// Handle API response and throw appropriate exceptions
  void _handleResponse(Response response) {
    final statusCode = response.statusCode;

    if (statusCode == null) {
      throw ServerException(
        message: 'No status code received',
        code: 0,
      );
    }

    // Handle specific status codes
    switch (statusCode) {
      case 200:
      case 201:
      case 204:
        return; // Success
      case 400:
        throw ValidationException(
          message: response.data?['message'] ?? 'Bad request',
          code: statusCode,
        );
      case 401:
        throw AuthException(
          message: 'Unauthorized. Please check your API key',
          code: statusCode,
        );
      case 403:
        throw AuthException(
          message: 'Forbidden. Access denied',
          code: statusCode,
        );
      case 404:
        throw ServerException(
          message: 'Resource not found',
          code: statusCode,
        );
      case 429:
        final retryAfter = response.headers.value('retry-after');
        throw RateLimitException(
          message: 'Rate limit exceeded',
          retryAfter: Duration(seconds: int.tryParse(retryAfter ?? '60') ?? 60),
          code: statusCode,
        );
      default:
        if (statusCode >= 500) {
          throw ServerException(
            message: 'Server error: ${response.statusMessage}',
            code: statusCode,
          );
        }
        throw ServerException(
          message: 'Unexpected error: ${response.statusMessage}',
          code: statusCode,
        );
    }
  }

  /// Determine if request should be retried based on error type
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        // Retry on server errors (5xx) but not on client errors (4xx)
        return statusCode != null && statusCode >= 500;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Calculate exponential backoff duration
  Duration _calculateBackoff(int attempt) {
    // Exponential backoff: 2^attempt seconds, capped at 60 seconds
    final seconds = (1 << attempt).clamp(1, 60);
    return Duration(seconds: seconds);
  }

  /// Map DioException to custom exceptions
  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Request timeout: ${error.message}',
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Network connection failed: ${error.message}',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return RateLimitException(
            message: 'Rate limit exceeded',
            retryAfter: const Duration(seconds: 60),
            code: statusCode,
          );
        }
        return ServerException(
          message: error.response?.statusMessage ?? 'Server error',
          code: statusCode,
        );
      case DioExceptionType.cancel:
        return AppException(
          message: 'Request cancelled',
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Bad certificate: ${error.message}',
        );
      case DioExceptionType.unknown:
        return AppException(
          message: 'Unknown error: ${error.message}',
        );
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
