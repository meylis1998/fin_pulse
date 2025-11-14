import 'package:equatable/equatable.dart';

/// Candlestick data entity for OHLC chart visualization
class Candlestick extends Equatable {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const Candlestick({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// Check if this candlestick is bullish (close > open)
  bool get isBullish => close > open;

  /// Get the body size (absolute difference between open and close)
  double get bodySize => (close - open).abs();

  /// Get the upper wick size (high - max of open/close)
  double get upperWickSize => high - (isBullish ? close : open);

  /// Get the lower wick size (min of open/close - low)
  double get lowerWickSize => (isBullish ? open : close) - low;

  @override
  List<Object?> get props => [timestamp, open, high, low, close, volume];
}
