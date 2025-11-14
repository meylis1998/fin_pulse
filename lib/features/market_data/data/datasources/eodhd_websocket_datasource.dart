import 'dart:async';
import 'dart:convert';

import 'package:fin_pulse/core/constants/api_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real-time price update model
class PriceUpdate {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final DateTime timestamp;

  PriceUpdate({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.timestamp,
  });

  factory PriceUpdate.fromJson(Map<String, dynamic> json) {
    return PriceUpdate(
      symbol: json['s'] as String,
      price: (json['p'] as num).toDouble(),
      change: (json['dc'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['dp'] as num?)?.toDouble() ?? 0.0,
      volume: (json['v'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as num).toInt(),
      ),
    );
  }
}

/// EODHD WebSocket API data source
///
/// Provides real-time stock price streaming with sub-50ms latency
/// Supports major tickers: AAPL, MSFT, TSLA, BTC-USD, etc.
abstract class EodhdWebSocketDataSource {
  Stream<PriceUpdate> subscribeToPriceUpdates(List<String> symbols);
  Future<void> subscribe(List<String> symbols);
  Future<void> unsubscribe(List<String> symbols);
  Future<void> disconnect();
  bool get isConnected;
}

class EodhdWebSocketDataSourceImpl implements EodhdWebSocketDataSource {
  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  final StreamController<PriceUpdate> _priceUpdateController =
      StreamController<PriceUpdate>.broadcast();
  final Set<String> _subscribedSymbols = {};
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  @override
  bool get isConnected => _isConnected;

  /// Initialize WebSocket connection
  Future<void> _connect() async {
    try {
      _logger.i('Connecting to EODHD WebSocket...');

      final wsUrl =
          '${ApiConstants.eodhdWebSocketUrl}/${ApiConstants.eodhdApiKey}';

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      // Wait for connection with timeout
      await _channel!.ready.timeout(
        ApiConstants.websocketTimeout,
        onTimeout: () {
          throw TimeoutException(
            message: 'WebSocket connection timeout',
          );
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _logger.i('WebSocket connected successfully');

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Resubscribe to previously subscribed symbols
      if (_subscribedSymbols.isNotEmpty) {
        await subscribe(_subscribedSymbols.toList());
      }
    } catch (e) {
      _logger.e('WebSocket connection failed', error: e);
      _isConnected = false;
      _attemptReconnect();
      throw WebSocketException(
        message: 'Failed to connect to WebSocket: $e',
      );
    }
  }

  @override
  Stream<PriceUpdate> subscribeToPriceUpdates(List<String> symbols) {
    subscribe(symbols);
    return _priceUpdateController.stream;
  }

  @override
  Future<void> subscribe(List<String> symbols) async {
    if (!_isConnected) {
      await _connect();
    }

    try {
      for (final symbol in symbols) {
        if (!_subscribedSymbols.contains(symbol)) {
          final message = jsonEncode({
            'action': ApiConstants.wsSubscribe,
            'symbols': symbol,
          });

          _channel?.sink.add(message);
          _subscribedSymbols.add(symbol);

          _logger.d('Subscribed to $symbol');
        }
      }
    } catch (e) {
      _logger.e('Failed to subscribe to symbols', error: e);
      throw WebSocketException(
        message: 'Failed to subscribe: $e',
      );
    }
  }

  @override
  Future<void> unsubscribe(List<String> symbols) async {
    if (!_isConnected) return;

    try {
      for (final symbol in symbols) {
        if (_subscribedSymbols.contains(symbol)) {
          final message = jsonEncode({
            'action': ApiConstants.wsUnsubscribe,
            'symbols': symbol,
          });

          _channel?.sink.add(message);
          _subscribedSymbols.remove(symbol);

          _logger.d('Unsubscribed from $symbol');
        }
      }
    } catch (e) {
      _logger.e('Failed to unsubscribe from symbols', error: e);
      throw WebSocketException(
        message: 'Failed to unsubscribe: $e',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.i('Disconnecting WebSocket...');

    _reconnectTimer?.cancel();
    _isConnected = false;
    _subscribedSymbols.clear();

    await _channel?.sink.close();
    _channel = null;

    _logger.i('WebSocket disconnected');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      // Check message type
      final type = data['type'] as String?;

      if (type == 'price' || type == ApiConstants.wsPriceUpdate) {
        final priceUpdate = PriceUpdate.fromJson(data);
        _priceUpdateController.add(priceUpdate);

        _logger.d(
          'Price update: ${priceUpdate.symbol} = \$${priceUpdate.price}',
        );
      } else if (type == 'ping') {
        // Respond to ping with pong
        _channel?.sink.add(jsonEncode({'type': 'pong'}));
      } else if (type == 'error') {
        _logger.e('WebSocket error message: ${data['message']}');
      }
    } catch (e) {
      _logger.e('Failed to parse WebSocket message', error: e);
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _logger.e('WebSocket error', error: error);
    _isConnected = false;
    _attemptReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    _logger.w('WebSocket disconnected');
    _isConnected = false;
    _attemptReconnect();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached. Giving up.');
      _priceUpdateController.addError(
        WebSocketException(
          message: 'Failed to reconnect after $_maxReconnectAttempts attempts',
        ),
      );
      return;
    }

    _reconnectAttempts++;
    final backoffDelay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(1, 60),
    );

    _logger.w(
      'Attempting to reconnect in ${backoffDelay.inSeconds}s... '
      '(Attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(backoffDelay, () {
      _connect().catchError((error) {
        _logger.e('Reconnection failed', error: error);
      });
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _priceUpdateController.close();
    _reconnectTimer?.cancel();
  }
}
