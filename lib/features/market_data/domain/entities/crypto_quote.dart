import 'package:equatable/equatable.dart';

/// Cryptocurrency quote entity
class CryptoQuote extends Equatable {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final double marketCap;
  final int marketCapRank;
  final double totalVolume;
  final double high24h;
  final double low24h;
  final DateTime lastUpdated;

  const CryptoQuote({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.marketCapRank,
    required this.totalVolume,
    required this.high24h,
    required this.low24h,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        symbol,
        name,
        currentPrice,
        priceChange24h,
        priceChangePercentage24h,
        marketCap,
        marketCapRank,
        totalVolume,
        high24h,
        low24h,
        lastUpdated,
      ];
}
