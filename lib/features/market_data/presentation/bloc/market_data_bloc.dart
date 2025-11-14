import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_crypto_quotes.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_stock_quote.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_technical_indicator.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/stream_real_time_price.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_event.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_state.dart';
import 'package:logger/logger.dart';

/// BLoC for managing market data state
///
/// Handles:
/// - Fetching stock/crypto quotes
/// - Company profiles and fundamentals
/// - Technical indicators
/// - Real-time price streaming via WebSocket
/// - Cache management
class MarketDataBloc extends Bloc<MarketDataEvent, MarketDataState> {
  final GetStockQuote getStockQuote;
  final GetCryptoQuote getCryptoQuote;
  final GetCryptoQuotes getCryptoQuotes;
  final GetCompanyProfile getCompanyProfile;
  final GetTechnicalIndicator getTechnicalIndicator;
  final StreamRealTimePrice streamRealTimePrice;

  final Logger _logger = Logger();
  StreamSubscription? _priceStreamSubscription;

  MarketDataBloc({
    required this.getStockQuote,
    required this.getCryptoQuote,
    required this.getCryptoQuotes,
    required this.getCompanyProfile,
    required this.getTechnicalIndicator,
    required this.streamRealTimePrice,
  }) : super(const MarketDataInitial()) {
    on<FetchStockQuoteEvent>(_onFetchStockQuote);
    on<FetchCryptoQuoteEvent>(_onFetchCryptoQuote);
    on<FetchCryptoQuotesEvent>(_onFetchCryptoQuotes);
    on<FetchCompanyProfileEvent>(_onFetchCompanyProfile);
    on<FetchTechnicalIndicatorEvent>(_onFetchTechnicalIndicator);
    on<SubscribeToRealTimePriceEvent>(_onSubscribeToRealTimePrice);
    on<UnsubscribeFromRealTimePriceEvent>(_onUnsubscribeFromRealTimePrice);
    on<RefreshMarketDataEvent>(_onRefreshMarketData);
    on<ClearCacheEvent>(_onClearCache);
  }

  /// Fetch stock quote
  Future<void> _onFetchStockQuote(
    FetchStockQuoteEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(MarketDataLoading(message: 'Fetching ${event.symbol}...'));

    final result =
        await getStockQuote(GetStockQuoteParams(symbol: event.symbol));

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (quote) {
        _logger.d('Stock quote fetched: ${quote.symbol} = \$${quote.price}');
        emit(StockQuoteLoaded(quote));
      },
    );
  }

  /// Fetch crypto quote
  Future<void> _onFetchCryptoQuote(
    FetchCryptoQuoteEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(MarketDataLoading(message: 'Fetching ${event.id}...'));

    final result = await getCryptoQuote(GetCryptoQuoteParams(id: event.id));

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (quote) {
        _logger.d(
            'Crypto quote fetched: ${quote.symbol} = \$${quote.currentPrice}');
        emit(CryptoQuoteLoaded(quote));
      },
    );
  }

  /// Fetch multiple crypto quotes
  Future<void> _onFetchCryptoQuotes(
    FetchCryptoQuotesEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(const MarketDataLoading(message: 'Fetching crypto markets...'));

    final result = await getCryptoQuotes(
      GetCryptoQuotesParams(ids: event.ids, limit: event.limit),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (quotes) {
        _logger.d('Fetched ${quotes.length} crypto quotes');
        emit(CryptoQuotesLoaded(quotes));
      },
    );
  }

  /// Fetch company profile
  Future<void> _onFetchCompanyProfile(
    FetchCompanyProfileEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(MarketDataLoading(message: 'Fetching company profile...'));

    final result = await getCompanyProfile(
      GetCompanyProfileParams(symbol: event.symbol),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (profile) {
        _logger.d('Company profile fetched: ${profile.name}');
        emit(CompanyProfileLoaded(profile));
      },
    );
  }

  /// Fetch technical indicator
  Future<void> _onFetchTechnicalIndicator(
    FetchTechnicalIndicatorEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(MarketDataLoading(message: 'Calculating ${event.indicator}...'));

    final result = await getTechnicalIndicator(
      GetTechnicalIndicatorParams(
        symbol: event.symbol,
        indicator: event.indicator,
        params: event.params,
      ),
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (data) {
        _logger.d('Technical indicator fetched: ${event.indicator}');
        emit(TechnicalIndicatorLoaded(
          symbol: event.symbol,
          indicator: event.indicator,
          data: data,
        ));
      },
    );
  }

  /// Subscribe to real-time price updates
  Future<void> _onSubscribeToRealTimePrice(
    SubscribeToRealTimePriceEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    _logger.i('Subscribing to real-time prices for ${event.symbol}');

    // Cancel existing subscription
    await _priceStreamSubscription?.cancel();

    // Subscribe to price stream
    final stream = streamRealTimePrice(
      StreamRealTimePriceParams(symbol: event.symbol),
    );

    _priceStreamSubscription = stream.listen(
      (result) {
        result.fold(
          (failure) => emit(_mapFailureToState(failure)),
          (quote) {
            _logger.d('Real-time update: ${quote.symbol} = \$${quote.price}');
            emit(RealTimePriceUpdate(
              quote: quote,
              timestamp: DateTime.now(),
            ));
          },
        );
      },
      onError: (error) {
        _logger.e('WebSocket error', error: error);
        emit(const MarketDataError(
          message: 'Real-time connection error',
        ));
      },
    );
  }

  /// Unsubscribe from real-time price updates
  Future<void> _onUnsubscribeFromRealTimePrice(
    UnsubscribeFromRealTimePriceEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    _logger.i('Unsubscribing from real-time prices');
    await _priceStreamSubscription?.cancel();
    _priceStreamSubscription = null;
    emit(const MarketDataInitial());
  }

  /// Refresh all market data
  Future<void> _onRefreshMarketData(
    RefreshMarketDataEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(const MarketDataLoading(message: 'Refreshing market data...'));

    // Add logic to refresh watchlist/portfolio data here
    // For now, just emit success
    await Future.delayed(const Duration(seconds: 1));

    emit(MarketDataRefreshed(DateTime.now()));
  }

  /// Clear cache
  Future<void> _onClearCache(
    ClearCacheEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(const MarketDataLoading(message: 'Clearing cache...'));

    // Cache clearing is handled by repository
    // In a real implementation, you'd call a use case here

    await Future.delayed(const Duration(milliseconds: 500));

    _logger.i('Cache cleared');
    emit(CacheCleared(DateTime.now()));
  }

  /// Map failure to appropriate state
  MarketDataState _mapFailureToState(Failure failure) {
    if (failure is RateLimitFailure) {
      return MarketDataRateLimitError(
        message: failure.message,
        retryAfter: failure.retryAfter,
      );
    } else if (failure is NetworkFailure) {
      return MarketDataNetworkError(message: failure.message);
    } else {
      return MarketDataError(
        message: failure.message,
        code: failure.code?.toString(),
      );
    }
  }

  @override
  Future<void> close() {
    _priceStreamSubscription?.cancel();
    return super.close();
  }
}
