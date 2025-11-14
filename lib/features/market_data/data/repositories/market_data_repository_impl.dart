import 'package:dartz/dartz.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/network/network_info.dart';
import 'package:fin_pulse/features/market_data/data/datasources/alpha_vantage_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/coingecko_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/eodhd_websocket_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/finnhub_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/firebase_cache_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/hive_cache_datasource.dart';
import 'package:fin_pulse/features/market_data/data/models/company_profile_model.dart';
import 'package:fin_pulse/features/market_data/data/models/crypto_quote_model.dart';
import 'package:fin_pulse/features/market_data/data/models/market_news_model.dart';
import 'package:fin_pulse/features/market_data/data/models/stock_quote_model.dart';
import 'package:fin_pulse/features/market_data/domain/entities/company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/entities/market_news.dart';
import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';
import 'package:logger/logger.dart';

/// Implementation of MarketDataRepository with three-tier caching strategy
///
/// Cache Strategy:
/// 1. Check Memory Cache (instant)
/// 2. Check Hive Cache (local, offline-first)
/// 3. Check Firebase Cache (cloud, collaborative)
/// 4. Fetch from remote API (with rate limiting)
/// 5. Update all cache layers
class MarketDataRepositoryImpl implements MarketDataRepository {
  final AlphaVantageDataSource alphaVantageDataSource;
  final CoinGeckoDataSource coinGeckoDataSource;
  final FinnhubDataSource finnhubDataSource;
  final EodhdWebSocketDataSource websocketDataSource;
  final FirebaseCacheDataSource firebaseCache;
  final HiveCacheDataSource hiveCache;
  final NetworkInfo networkInfo;
  final Logger _logger = Logger();

  // Layer 1: Memory cache (instant access)
  final Map<String, StockQuoteModel> _stockQuoteMemoryCache = {};
  final Map<String, CryptoQuoteModel> _cryptoQuoteMemoryCache = {};

  MarketDataRepositoryImpl({
    required this.alphaVantageDataSource,
    required this.coinGeckoDataSource,
    required this.finnhubDataSource,
    required this.websocketDataSource,
    required this.firebaseCache,
    required this.hiveCache,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, StockQuote>> getStockQuote(String symbol) async {
    try {
      // Layer 1: Check memory cache
      if (_stockQuoteMemoryCache.containsKey(symbol)) {
        _logger.d('Stock quote for $symbol found in memory cache');
        return Right(_stockQuoteMemoryCache[symbol]!.toEntity());
      }

      // Layer 2: Check Hive cache
      final hiveData = await hiveCache.getCachedStockQuote(symbol);
      if (hiveData != null) {
        _logger.d('Stock quote for $symbol found in Hive cache');
        final model = StockQuoteModel.fromJson(hiveData);
        _stockQuoteMemoryCache[symbol] = model;
        return Right(model.toEntity());
      }

      // Layer 3: Check Firebase cache
      final firebaseData = await firebaseCache.getCachedStockQuote(symbol);
      if (firebaseData != null) {
        _logger.d('Stock quote for $symbol found in Firebase cache');
        _stockQuoteMemoryCache[symbol] = firebaseData;
        await hiveCache.cacheStockQuote(symbol, firebaseData.toJson());
        return Right(firebaseData.toEntity());
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      // Fetch from remote API (Finnhub for real-time quotes)
      _logger.d('Fetching stock quote for $symbol from Finnhub API');
      final quote = await finnhubDataSource.getStockQuote(symbol);

      // Update all cache layers
      _stockQuoteMemoryCache[symbol] = quote;
      await hiveCache.cacheStockQuote(symbol, quote.toJson());
      await firebaseCache.cacheStockQuote(quote);

      return Right(quote.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(
        message: e.message,
        retryAfter: e.retryAfter,
        code: e.code,
      ));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('Unexpected error fetching stock quote', error: e);
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, CryptoQuote>> getCryptoQuote(String id) async {
    try {
      // Layer 1: Check memory cache
      if (_cryptoQuoteMemoryCache.containsKey(id)) {
        _logger.d('Crypto quote for $id found in memory cache');
        return Right(_cryptoQuoteMemoryCache[id]!.toEntity());
      }

      // Layer 2: Check Hive cache
      final hiveData = await hiveCache.getCachedCryptoQuote(id);
      if (hiveData != null) {
        _logger.d('Crypto quote for $id found in Hive cache');
        final model = CryptoQuoteModel.fromJson(hiveData);
        _cryptoQuoteMemoryCache[id] = model;
        return Right(model.toEntity());
      }

      // Layer 3: Check Firebase cache
      final firebaseData = await firebaseCache.getCachedCryptoQuote(id);
      if (firebaseData != null) {
        _logger.d('Crypto quote for $id found in Firebase cache');
        _cryptoQuoteMemoryCache[id] = firebaseData;
        await hiveCache.cacheCryptoQuote(id, firebaseData.toJson());
        return Right(firebaseData.toEntity());
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      // Fetch from CoinGecko API
      _logger.d('Fetching crypto quote for $id from CoinGecko API');
      final quotes = await coinGeckoDataSource.getCoinsMarkets(ids: [id]);

      if (quotes.isEmpty) {
        return Left(ServerFailure(message: 'Crypto not found: $id'));
      }

      final quote = CryptoQuoteModel.fromCoinGecko(quotes.first);

      // Update all cache layers
      _cryptoQuoteMemoryCache[id] = quote;
      await hiveCache.cacheCryptoQuote(id, quote.toJson());
      await firebaseCache.cacheCryptoQuote(quote);

      return Right(quote.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(
        message: e.message,
        retryAfter: e.retryAfter,
        code: e.code,
      ));
    } catch (e) {
      _logger.e('Unexpected error fetching crypto quote', error: e);
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CryptoQuote>>> getCryptoQuotes({
    List<String>? ids,
    int limit = 100,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      final quotes = await coinGeckoDataSource.getCoinsMarkets(
        ids: ids,
        perPage: limit,
      );

      final models =
          quotes.map((json) => CryptoQuoteModel.fromCoinGecko(json)).toList();

      // Update caches
      for (final model in models) {
        _cryptoQuoteMemoryCache[model.id] = model;
        hiveCache.cacheCryptoQuote(model.id, model.toJson());
        firebaseCache.cacheCryptoQuote(model);
      }

      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, CompanyProfile>> getCompanyProfile(
    String symbol,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      final data = await finnhubDataSource.getCompanyProfile(symbol);
      final profile = CompanyProfileModel.fromFinnhub(data);

      return Right(profile.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MarketNews>>> getCompanyNews(
    String symbol, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      final newsData = await finnhubDataSource.getCompanyNews(
        symbol,
        from: from,
        to: to,
      );

      final news =
          newsData.map((json) => MarketNewsModel.fromFinnhub(json)).toList();

      return Right(news.map((n) => n.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getIntradayData(
    String symbol, {
    String interval = '5min',
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      final data = await alphaVantageDataSource.getIntradayData(
        symbol,
        interval: interval,
      );

      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(
        message: e.message,
        retryAfter: e.retryAfter,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTechnicalIndicator(
    String symbol,
    String indicator, {
    Map<String, dynamic>? params,
  }) async {
    try {
      // Check Firebase cache first
      final cachedData = await firebaseCache.getCachedTechnicalIndicator(
        symbol,
        indicator,
      );

      if (cachedData != null) {
        _logger.d('Technical indicator $indicator for $symbol found in cache');
        return Right(cachedData);
      }

      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      final data = await alphaVantageDataSource.getTechnicalIndicator(
        symbol,
        indicator,
        params: params,
      );

      // Cache the result
      await firebaseCache.cacheTechnicalIndicator(symbol, indicator, data);

      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(
        message: e.message,
        retryAfter: e.retryAfter,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Stream<Either<Failure, StockQuote>> streamRealTimePrice(
      String symbol) async* {
    try {
      // Subscribe to WebSocket
      await websocketDataSource.subscribe([symbol]);

      // Listen to price updates
      await for (final update
          in websocketDataSource.subscribeToPriceUpdates([symbol])) {
        if (update.symbol == symbol) {
          final quote = StockQuoteModel(
            symbol: update.symbol,
            price: update.price,
            change: update.change,
            changePercent: update.changePercent,
            open: 0, // Not available in real-time update
            high: 0,
            low: 0,
            previousClose: 0,
            volume: update.volume,
            timestamp: update.timestamp,
          );

          // Update memory cache
          _stockQuoteMemoryCache[symbol] = quote;

          yield Right(quote.toEntity());
        }
      }
    } on WebSocketException catch (e) {
      yield Left(WebSocketFailure(message: e.message, code: e.code));
    } catch (e) {
      yield Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> subscribeToRealTimePrices(
    List<String> symbols,
  ) async {
    try {
      await websocketDataSource.subscribe(symbols);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromRealTimePrices(
    List<String> symbols,
  ) async {
    try {
      await websocketDataSource.unsubscribe(symbols);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      _stockQuoteMemoryCache.clear();
      _cryptoQuoteMemoryCache.clear();
      await hiveCache.clearCache();
      await firebaseCache.clearCache();

      _logger.i('All caches cleared');
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }
}
