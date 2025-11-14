import 'package:equatable/equatable.dart';
import 'package:fin_pulse/features/market_data/domain/entities/company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';

/// Base class for all MarketData states
abstract class MarketDataState extends Equatable {
  const MarketDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MarketDataInitial extends MarketDataState {
  const MarketDataInitial();
}

/// Loading state
class MarketDataLoading extends MarketDataState {
  final String? message;

  const MarketDataLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Stock quote loaded state
class StockQuoteLoaded extends MarketDataState {
  final StockQuote quote;

  const StockQuoteLoaded(this.quote);

  @override
  List<Object?> get props => [quote];
}

/// Crypto quote loaded state
class CryptoQuoteLoaded extends MarketDataState {
  final CryptoQuote quote;

  const CryptoQuoteLoaded(this.quote);

  @override
  List<Object?> get props => [quote];
}

/// Multiple crypto quotes loaded state
class CryptoQuotesLoaded extends MarketDataState {
  final List<CryptoQuote> quotes;

  const CryptoQuotesLoaded(this.quotes);

  @override
  List<Object?> get props => [quotes];
}

/// Company profile loaded state
class CompanyProfileLoaded extends MarketDataState {
  final CompanyProfile profile;

  const CompanyProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Technical indicator loaded state
class TechnicalIndicatorLoaded extends MarketDataState {
  final String symbol;
  final String indicator;
  final Map<String, dynamic> data;

  const TechnicalIndicatorLoaded({
    required this.symbol,
    required this.indicator,
    required this.data,
  });

  @override
  List<Object?> get props => [symbol, indicator, data];
}

/// Real-time price update state
class RealTimePriceUpdate extends MarketDataState {
  final StockQuote quote;
  final DateTime timestamp;

  const RealTimePriceUpdate({
    required this.quote,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [quote, timestamp];
}

/// Market data refreshed state
class MarketDataRefreshed extends MarketDataState {
  final DateTime timestamp;

  const MarketDataRefreshed(this.timestamp);

  @override
  List<Object?> get props => [timestamp];
}

/// Cache cleared state
class CacheCleared extends MarketDataState {
  final DateTime timestamp;

  const CacheCleared(this.timestamp);

  @override
  List<Object?> get props => [timestamp];
}

/// Error state
class MarketDataError extends MarketDataState {
  final String message;
  final String? code;

  const MarketDataError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Rate limit error state (special case with retry info)
class MarketDataRateLimitError extends MarketDataState {
  final String message;
  final Duration retryAfter;

  const MarketDataRateLimitError({
    required this.message,
    required this.retryAfter,
  });

  @override
  List<Object?> get props => [message, retryAfter];
}

/// Network error state (special case for offline)
class MarketDataNetworkError extends MarketDataState {
  final String message;

  const MarketDataNetworkError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
