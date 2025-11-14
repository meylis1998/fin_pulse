import 'package:equatable/equatable.dart';

/// Base class for watchlist events
abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

/// Load watchlist
class LoadWatchlistEvent extends WatchlistEvent {
  const LoadWatchlistEvent();
}

/// Add symbol to watchlist
class AddToWatchlistEvent extends WatchlistEvent {
  final String symbol;
  final bool isCrypto;

  const AddToWatchlistEvent({
    required this.symbol,
    this.isCrypto = false,
  });

  @override
  List<Object?> get props => [symbol, isCrypto];
}

/// Remove symbol from watchlist
class RemoveFromWatchlistEvent extends WatchlistEvent {
  final String symbol;

  const RemoveFromWatchlistEvent(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Refresh watchlist data
class RefreshWatchlistEvent extends WatchlistEvent {
  const RefreshWatchlistEvent();
}

/// Subscribe to real-time updates for watchlist
class SubscribeToWatchlistUpdatesEvent extends WatchlistEvent {
  const SubscribeToWatchlistUpdatesEvent();
}

/// Unsubscribe from real-time updates
class UnsubscribeFromWatchlistUpdatesEvent extends WatchlistEvent {
  const UnsubscribeFromWatchlistUpdatesEvent();
}

/// Search for symbol
class SearchSymbolEvent extends WatchlistEvent {
  final String query;

  const SearchSymbolEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clear search
class ClearSearchEvent extends WatchlistEvent {
  const ClearSearchEvent();
}
