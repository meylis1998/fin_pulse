// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_quote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CryptoQuoteModel _$CryptoQuoteModelFromJson(Map<String, dynamic> json) =>
    CryptoQuoteModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      priceChange24h: (json['priceChange24h'] as num).toDouble(),
      priceChangePercentage24h:
          (json['priceChangePercentage24h'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      marketCapRank: (json['marketCapRank'] as num).toInt(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      high24h: (json['high24h'] as num).toDouble(),
      low24h: (json['low24h'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$CryptoQuoteModelToJson(CryptoQuoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'name': instance.name,
      'currentPrice': instance.currentPrice,
      'priceChange24h': instance.priceChange24h,
      'priceChangePercentage24h': instance.priceChangePercentage24h,
      'marketCap': instance.marketCap,
      'marketCapRank': instance.marketCapRank,
      'totalVolume': instance.totalVolume,
      'high24h': instance.high24h,
      'low24h': instance.low24h,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
