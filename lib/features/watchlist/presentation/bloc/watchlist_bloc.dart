import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fin_pulse/core/constants/app_constants.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_event.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_state.dart';
import 'package:logger/logger.dart';

/// BLoC for managing watchlist state
///
/// Handles:
/// - Adding/removing symbols
/// - Real-time price updates
/// - Symbol search
/// - Watchlist persistence
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final Logger _logger = Logger();
  final List<String> _symbols = [];
  Timer? _updateTimer;

  WatchlistBloc() : super(const WatchlistInitial()) {
    on<LoadWatchlistEvent>(_onLoadWatchlist);
    on<AddToWatchlistEvent>(_onAddToWatchlist);
    on<RemoveFromWatchlistEvent>(_onRemoveFromWatchlist);
    on<RefreshWatchlistEvent>(_onRefreshWatchlist);
    on<SubscribeToWatchlistUpdatesEvent>(_onSubscribeToUpdates);
    on<UnsubscribeFromWatchlistUpdatesEvent>(_onUnsubscribeFromUpdates);
    on<SearchSymbolEvent>(_onSearchSymbol);
    on<ClearSearchEvent>(_onClearSearch);
  }

  /// Load watchlist from cache/storage
  Future<void> _onLoadWatchlist(
    LoadWatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistLoading());

    // Load from default or cache
    // For now, use default tickers
    _symbols.clear();
    _symbols.addAll([
      ...AppConstants.defaultStockTickers,
      ...AppConstants.defaultCryptoTickers,
    ]);

    final items = _symbols.map((symbol) {
      return WatchlistItem(
        symbol: symbol,
        isCrypto: AppConstants.defaultCryptoTickers.contains(symbol),
      );
    }).toList();

    _logger.i('Watchlist loaded: ${_symbols.length} symbols');
    emit(WatchlistLoaded(items: items));
  }

  /// Add symbol to watchlist
  Future<void> _onAddToWatchlist(
    AddToWatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    if (_symbols.contains(event.symbol)) {
      emit(const WatchlistError('Symbol already in watchlist'));
      return;
    }

    _symbols.add(event.symbol);

    final items = _symbols.map((symbol) {
      return WatchlistItem(
        symbol: symbol,
        isCrypto: event.isCrypto,
      );
    }).toList();

    _logger.i('Added ${event.symbol} to watchlist');
    emit(WatchlistLoaded(items: items));
  }

  /// Remove symbol from watchlist
  Future<void> _onRemoveFromWatchlist(
    RemoveFromWatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    _symbols.remove(event.symbol);

    final items = _symbols.map((symbol) {
      return WatchlistItem(symbol: symbol);
    }).toList();

    _logger.i('Removed ${event.symbol} from watchlist');
    emit(WatchlistLoaded(items: items));
  }

  /// Refresh watchlist data
  Future<void> _onRefreshWatchlist(
    RefreshWatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistLoading());

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));

    final items = _symbols.map((symbol) {
      return WatchlistItem(
        symbol: symbol,
        lastUpdated: DateTime.now(),
      );
    }).toList();

    emit(WatchlistLoaded(items: items));
  }

  /// Subscribe to real-time updates
  Future<void> _onSubscribeToUpdates(
    SubscribeToWatchlistUpdatesEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    _logger.i('Subscribing to watchlist updates');

    // Start periodic updates (simulated)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (state is WatchlistLoaded) {
        final current = state as WatchlistLoaded;
        emit(WatchlistUpdated(
          items: current.items,
          timestamp: DateTime.now(),
        ));
      }
    });

    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      emit(current.copyWith(isSubscribed: true));
    }
  }

  /// Unsubscribe from real-time updates
  Future<void> _onUnsubscribeFromUpdates(
    UnsubscribeFromWatchlistUpdatesEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    _logger.i('Unsubscribing from watchlist updates');
    _updateTimer?.cancel();

    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      emit(current.copyWith(isSubscribed: false));
    }
  }

  /// Search for symbol
  Future<void> _onSearchSymbol(
    SearchSymbolEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const ClearSearchEvent());
      return;
    }

    // Simple search in available symbols
    final results = [
      ...AppConstants.defaultStockTickers,
      ...AppConstants.defaultCryptoTickers,
    ].where((symbol) {
      return symbol.toLowerCase().contains(event.query.toLowerCase());
    }).toList();

    emit(WatchlistSearchResults(query: event.query, results: results));
  }

  /// Clear search
  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final items = _symbols.map((symbol) {
      return WatchlistItem(symbol: symbol);
    }).toList();

    emit(WatchlistLoaded(items: items));
  }

  @override
  Future<void> close() {
    _updateTimer?.cancel();
    return super.close();
  }
}
