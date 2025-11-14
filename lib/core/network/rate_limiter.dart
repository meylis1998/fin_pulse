import 'dart:async';
import 'dart:collection';

import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:logger/logger.dart';

/// Request priority levels
enum RequestPriority {
  low,
  normal,
  high,
  critical,
}

/// Token Bucket Rate Limiter implementation
///
/// Uses the token bucket algorithm to enforce rate limits for API calls.
/// Supports priority-based request queuing and exponential backoff.
class RateLimiter {
  final int maxTokens;
  final Duration refillPeriod;
  final Logger _logger = Logger();

  int _tokens;
  DateTime _lastRefillTime;
  final Queue<_QueuedRequest> _requestQueue = Queue();
  Timer? _refillTimer;
  bool _isProcessing = false;

  RateLimiter({
    required this.maxTokens,
    required this.refillPeriod,
  })  : _tokens = maxTokens,
        _lastRefillTime = DateTime.now() {
    _startRefillTimer();
  }

  /// Execute a function with rate limiting
  Future<T> execute<T>({
    required Future<T> Function() function,
    RequestPriority priority = RequestPriority.normal,
    int tokensRequired = 1,
  }) async {
    final completer = Completer<T>();
    final request = _QueuedRequest(
      function: () async {
        try {
          final result = await function();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      },
      priority: priority,
      tokensRequired: tokensRequired,
      completer: completer,
    );

    _requestQueue.add(request);
    _processQueue();

    return completer.future;
  }

  /// Process queued requests based on available tokens
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_requestQueue.isNotEmpty) {
      _refillTokens();

      // Sort queue by priority
      final sortedQueue = _requestQueue.toList()
        ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

      bool requestProcessed = false;

      for (final request in sortedQueue) {
        if (_tokens >= request.tokensRequired) {
          _tokens -= request.tokensRequired;
          _requestQueue.remove(request);

          _logger.d(
            'Executing request (Priority: ${request.priority}, '
            'Tokens: ${request.tokensRequired}, '
            'Remaining: $_tokens/$maxTokens)',
          );

          // Execute without awaiting to allow concurrent processing
          request.function();
          requestProcessed = true;
          break;
        }
      }

      if (!requestProcessed) {
        // No request can be processed, wait for refill
        _logger.w('Rate limit reached. Waiting for token refill...');
        await _waitForRefill();
      }
    }

    _isProcessing = false;
  }

  /// Refill tokens based on elapsed time
  void _refillTokens() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefillTime);

    if (elapsed >= refillPeriod) {
      final periods = elapsed.inMilliseconds / refillPeriod.inMilliseconds;
      final tokensToAdd = (periods * maxTokens).floor();

      _tokens = (_tokens + tokensToAdd).clamp(0, maxTokens);
      _lastRefillTime = now;

      _logger.d('Tokens refilled: $_tokens/$maxTokens');
    }
  }

  /// Start automatic token refill timer
  void _startRefillTimer() {
    _refillTimer?.cancel();
    _refillTimer = Timer.periodic(refillPeriod, (_) {
      _refillTokens();
      if (_requestQueue.isNotEmpty && !_isProcessing) {
        _processQueue();
      }
    });
  }

  /// Wait for token refill
  Future<void> _waitForRefill() async {
    final waitTime = refillPeriod;
    _logger.d('Waiting ${waitTime.inSeconds}s for token refill');
    await Future.delayed(waitTime);
    _refillTokens();
  }

  /// Get current token count
  int get availableTokens => _tokens;

  /// Get queue length
  int get queueLength => _requestQueue.length;

  /// Check if rate limit is available
  bool canExecute({int tokensRequired = 1}) {
    _refillTokens();
    return _tokens >= tokensRequired;
  }

  /// Clear the request queue
  void clearQueue() {
    for (final request in _requestQueue) {
      request.completer.completeError(
        RateLimitException(
          message: 'Request cancelled: Queue cleared',
          retryAfter: Duration.zero,
        ),
      );
    }
    _requestQueue.clear();
  }

  /// Dispose resources
  void dispose() {
    _refillTimer?.cancel();
    clearQueue();
  }
}

/// Internal class to represent a queued request
class _QueuedRequest {
  final Future<void> Function() function;
  final RequestPriority priority;
  final int tokensRequired;
  final Completer completer;

  _QueuedRequest({
    required this.function,
    required this.priority,
    required this.tokensRequired,
    required this.completer,
  });
}

/// Rate Limiter Manager for multiple APIs
class RateLimiterManager {
  static final RateLimiterManager _instance = RateLimiterManager._internal();
  factory RateLimiterManager() => _instance;
  RateLimiterManager._internal();

  final Map<String, RateLimiter> _limiters = {};

  /// Get or create a rate limiter for a specific API
  RateLimiter getLimiter(
    String apiName, {
    required int maxTokens,
    required Duration refillPeriod,
  }) {
    return _limiters.putIfAbsent(
      apiName,
      () => RateLimiter(
        maxTokens: maxTokens,
        refillPeriod: refillPeriod,
      ),
    );
  }

  /// Dispose all rate limiters
  void disposeAll() {
    for (final limiter in _limiters.values) {
      limiter.dispose();
    }
    _limiters.clear();
  }
}
