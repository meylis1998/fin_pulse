import 'package:equatable/equatable.dart';

/// Base class for all MarketData events
abstract class MarketDataEvent extends Equatable {
  const MarketDataEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch stock quote
class FetchStockQuoteEvent extends MarketDataEvent {
  final String symbol;

  const FetchStockQuoteEvent(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Event to fetch crypto quote
class FetchCryptoQuoteEvent extends MarketDataEvent {
  final String id;

  const FetchCryptoQuoteEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to fetch multiple crypto quotes
class FetchCryptoQuotesEvent extends MarketDataEvent {
  final List<String>? ids;
  final int limit;

  const FetchCryptoQuotesEvent({this.ids, this.limit = 100});

  @override
  List<Object?> get props => [ids, limit];
}

/// Event to fetch company profile
class FetchCompanyProfileEvent extends MarketDataEvent {
  final String symbol;

  const FetchCompanyProfileEvent(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Event to fetch technical indicator
class FetchTechnicalIndicatorEvent extends MarketDataEvent {
  final String symbol;
  final String indicator;
  final Map<String, dynamic>? params;

  const FetchTechnicalIndicatorEvent({
    required this.symbol,
    required this.indicator,
    this.params,
  });

  @override
  List<Object?> get props => [symbol, indicator, params];
}

/// Event to subscribe to real-time price updates
class SubscribeToRealTimePriceEvent extends MarketDataEvent {
  final String symbol;

  const SubscribeToRealTimePriceEvent(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Event to unsubscribe from real-time price updates
class UnsubscribeFromRealTimePriceEvent extends MarketDataEvent {
  final String symbol;

  const UnsubscribeFromRealTimePriceEvent(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Event to refresh all market data
class RefreshMarketDataEvent extends MarketDataEvent {
  const RefreshMarketDataEvent();
}

/// Event to clear cache
class ClearCacheEvent extends MarketDataEvent {
  const ClearCacheEvent();
}
