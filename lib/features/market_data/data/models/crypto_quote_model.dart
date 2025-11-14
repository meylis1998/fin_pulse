import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:json_annotation/json_annotation.dart';

part 'crypto_quote_model.g.dart';

@JsonSerializable()
class CryptoQuoteModel extends CryptoQuote {
  const CryptoQuoteModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.currentPrice,
    required super.priceChange24h,
    required super.priceChangePercentage24h,
    required super.marketCap,
    required super.marketCapRank,
    required super.totalVolume,
    required super.high24h,
    required super.low24h,
    required super.lastUpdated,
  });

  factory CryptoQuoteModel.fromJson(Map<String, dynamic> json) =>
      _$CryptoQuoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$CryptoQuoteModelToJson(this);

  /// Create from CoinGecko API response
  factory CryptoQuoteModel.fromCoinGecko(Map<String, dynamic> json) {
    return CryptoQuoteModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0.0,
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      high24h: (json['high_24h'] as num?)?.toDouble() ?? 0.0,
      low24h: (json['low_24h'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  CryptoQuote toEntity() => CryptoQuote(
        id: id,
        symbol: symbol,
        name: name,
        currentPrice: currentPrice,
        priceChange24h: priceChange24h,
        priceChangePercentage24h: priceChangePercentage24h,
        marketCap: marketCap,
        marketCapRank: marketCapRank,
        totalVolume: totalVolume,
        high24h: high24h,
        low24h: low24h,
        lastUpdated: lastUpdated,
      );
}
