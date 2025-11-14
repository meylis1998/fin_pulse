import 'package:equatable/equatable.dart';

/// Watchlist item
class WatchlistItem extends Equatable {
  final String symbol;
  final bool isCrypto;
  final double? currentPrice;
  final double? changePercent;
  final DateTime? lastUpdated;

  const WatchlistItem({
    required this.symbol,
    this.isCrypto = false,
    this.currentPrice,
    this.changePercent,
    this.lastUpdated,
  });

  WatchlistItem copyWith({
    String? symbol,
    bool? isCrypto,
    double? currentPrice,
    double? changePercent,
    DateTime? lastUpdated,
  }) {
    return WatchlistItem(
      symbol: symbol ?? this.symbol,
      isCrypto: isCrypto ?? this.isCrypto,
      currentPrice: currentPrice ?? this.currentPrice,
      changePercent: changePercent ?? this.changePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        isCrypto,
        currentPrice,
        changePercent,
        lastUpdated,
      ];
}

/// Base watchlist state
abstract class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

/// Loading state
class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

/// Loaded state
class WatchlistLoaded extends WatchlistState {
  final List<WatchlistItem> items;
  final bool isSubscribed;

  const WatchlistLoaded({
    required this.items,
    this.isSubscribed = false,
  });

  @override
  List<Object?> get props => [items, isSubscribed];

  WatchlistLoaded copyWith({
    List<WatchlistItem>? items,
    bool? isSubscribed,
  }) {
    return WatchlistLoaded(
      items: items ?? this.items,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Watchlist updated (real-time)
class WatchlistUpdated extends WatchlistState {
  final List<WatchlistItem> items;
  final DateTime timestamp;

  const WatchlistUpdated({
    required this.items,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [items, timestamp];
}

/// Search results
class WatchlistSearchResults extends WatchlistState {
  final String query;
  final List<String> results;

  const WatchlistSearchResults({
    required this.query,
    required this.results,
  });

  @override
  List<Object?> get props => [query, results];
}

/// Error state
class WatchlistError extends WatchlistState {
  final String message;

  const WatchlistError(this.message);

  @override
  List<Object?> get props => [message];
}
