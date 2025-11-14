import 'package:equatable/equatable.dart';

/// Stock quote entity
class StockQuote extends Equatable {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double previousClose;
  final int volume;
  final DateTime timestamp;

  const StockQuote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.previousClose,
    required this.volume,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        symbol,
        price,
        change,
        changePercent,
        open,
        high,
        low,
        previousClose,
        volume,
        timestamp,
      ];
}
