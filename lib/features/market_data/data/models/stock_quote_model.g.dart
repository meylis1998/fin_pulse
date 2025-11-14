// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_quote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockQuoteModel _$StockQuoteModelFromJson(Map<String, dynamic> json) =>
    StockQuoteModel(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      previousClose: (json['previousClose'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$StockQuoteModelToJson(StockQuoteModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'price': instance.price,
      'change': instance.change,
      'changePercent': instance.changePercent,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'previousClose': instance.previousClose,
      'volume': instance.volume,
      'timestamp': instance.timestamp.toIso8601String(),
    };
