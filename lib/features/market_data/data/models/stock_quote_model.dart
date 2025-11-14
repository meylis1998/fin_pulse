import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stock_quote_model.g.dart';

@JsonSerializable()
class StockQuoteModel extends StockQuote {
  const StockQuoteModel({
    required super.symbol,
    required super.price,
    required super.change,
    required super.changePercent,
    required super.open,
    required super.high,
    required super.low,
    required super.previousClose,
    required super.volume,
    required super.timestamp,
  });

  factory StockQuoteModel.fromJson(Map<String, dynamic> json) =>
      _$StockQuoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockQuoteModelToJson(this);

  /// Create from Finnhub API response
  factory StockQuoteModel.fromFinnhub(
    String symbol,
    Map<String, dynamic> json,
  ) {
    return StockQuoteModel(
      symbol: symbol,
      price: (json['c'] as num).toDouble(),
      change: (json['d'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['dp'] as num?)?.toDouble() ?? 0.0,
      open: (json['o'] as num).toDouble(),
      high: (json['h'] as num).toDouble(),
      low: (json['l'] as num).toDouble(),
      previousClose: (json['pc'] as num).toDouble(),
      volume: (json['v'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as num).toInt() * 1000,
      ),
    );
  }

  /// Create from Alpha Vantage API response
  factory StockQuoteModel.fromAlphaVantage(
    String symbol,
    Map<String, dynamic> json,
  ) {
    final quote = json['Global Quote'] as Map<String, dynamic>;
    return StockQuoteModel(
      symbol: symbol,
      price: double.parse(quote['05. price']),
      change: double.parse(quote['09. change']),
      changePercent: double.parse(
        quote['10. change percent'].toString().replaceAll('%', ''),
      ),
      open: double.parse(quote['02. open']),
      high: double.parse(quote['03. high']),
      low: double.parse(quote['04. low']),
      previousClose: double.parse(quote['08. previous close']),
      volume: int.parse(quote['06. volume']),
      timestamp: DateTime.now(),
    );
  }

  StockQuote toEntity() => StockQuote(
        symbol: symbol,
        price: price,
        change: change,
        changePercent: changePercent,
        open: open,
        high: high,
        low: low,
        previousClose: previousClose,
        volume: volume,
        timestamp: timestamp,
      );
}
