import 'package:fin_pulse/core/constants/app_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:fin_pulse/features/market_data/data/models/crypto_quote_model.dart';
import 'package:fin_pulse/features/market_data/data/models/stock_quote_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

/// Firebase Realtime Database cache data source
///
/// Layer 3 caching: Cloud-based shared market data with real-time sync
/// Use for collaborative features and cross-device synchronization
abstract class FirebaseCacheDataSource {
  Future<void> cacheStockQuote(StockQuoteModel quote);
  Future<StockQuoteModel?> getCachedStockQuote(String symbol);
  Future<void> cacheCryptoQuote(CryptoQuoteModel quote);
  Future<CryptoQuoteModel?> getCachedCryptoQuote(String id);
  Future<void> cacheTechnicalIndicator(
    String symbol,
    String indicator,
    Map<String, dynamic> data,
  );
  Future<Map<String, dynamic>?> getCachedTechnicalIndicator(
    String symbol,
    String indicator,
  );
  Stream<StockQuoteModel> watchStockQuote(String symbol);
  Stream<CryptoQuoteModel> watchCryptoQuote(String id);
  Future<void> clearCache();
}

class FirebaseCacheDataSourceImpl implements FirebaseCacheDataSource {
  final FirebaseDatabase _database;
  final Logger _logger = Logger();

  FirebaseCacheDataSourceImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference get _marketDataRef =>
      _database.ref(AppConstants.marketDataPath);
  DatabaseReference get _stocksRef =>
      _marketDataRef.child(AppConstants.stocksPath);
  DatabaseReference get _cryptoRef =>
      _marketDataRef.child(AppConstants.cryptoPath);
  DatabaseReference get _technicalIndicatorsRef =>
      _marketDataRef.child(AppConstants.technicalIndicatorsPath);

  @override
  Future<void> cacheStockQuote(StockQuoteModel quote) async {
    try {
      final data = {
        'symbol': quote.symbol,
        'price': quote.price,
        'change': quote.change,
        'changePercent': quote.changePercent,
        'open': quote.open,
        'high': quote.high,
        'low': quote.low,
        'previousClose': quote.previousClose,
        'volume': quote.volume,
        'timestamp': quote.timestamp.millisecondsSinceEpoch,
        'cachedAt': ServerValue.timestamp,
      };

      await _stocksRef.child(quote.symbol).child('quote').set(data);

      _logger.d('Cached stock quote for ${quote.symbol} to Firebase');
    } catch (e) {
      _logger.e('Failed to cache stock quote to Firebase', error: e);
      throw CacheException(
        message: 'Failed to cache stock quote: $e',
      );
    }
  }

  @override
  Future<StockQuoteModel?> getCachedStockQuote(String symbol) async {
    try {
      final snapshot = await _stocksRef.child(symbol).child('quote').get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if cache is stale
      final cachedAt = data['cachedAt'] as int?;
      if (cachedAt != null &&
          _isCacheStale(cachedAt, AppConstants.realTimePriceTTL)) {
        _logger.d('Stock quote cache for $symbol is stale');
        return null;
      }

      return StockQuoteModel(
        symbol: data['symbol'] as String,
        price: (data['price'] as num).toDouble(),
        change: (data['change'] as num).toDouble(),
        changePercent: (data['changePercent'] as num).toDouble(),
        open: (data['open'] as num).toDouble(),
        high: (data['high'] as num).toDouble(),
        low: (data['low'] as num).toDouble(),
        previousClose: (data['previousClose'] as num).toDouble(),
        volume: (data['volume'] as num).toInt(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] as int,
        ),
      );
    } catch (e) {
      _logger.e('Failed to get cached stock quote from Firebase', error: e);
      return null;
    }
  }

  @override
  Future<void> cacheCryptoQuote(CryptoQuoteModel quote) async {
    try {
      final data = {
        'id': quote.id,
        'symbol': quote.symbol,
        'name': quote.name,
        'currentPrice': quote.currentPrice,
        'priceChange24h': quote.priceChange24h,
        'priceChangePercentage24h': quote.priceChangePercentage24h,
        'marketCap': quote.marketCap,
        'marketCapRank': quote.marketCapRank,
        'totalVolume': quote.totalVolume,
        'high24h': quote.high24h,
        'low24h': quote.low24h,
        'lastUpdated': quote.lastUpdated.millisecondsSinceEpoch,
        'cachedAt': ServerValue.timestamp,
      };

      await _cryptoRef.child(quote.id).child('price').set(data);

      _logger.d('Cached crypto quote for ${quote.symbol} to Firebase');
    } catch (e) {
      _logger.e('Failed to cache crypto quote to Firebase', error: e);
      throw CacheException(
        message: 'Failed to cache crypto quote: $e',
      );
    }
  }

  @override
  Future<CryptoQuoteModel?> getCachedCryptoQuote(String id) async {
    try {
      final snapshot = await _cryptoRef.child(id).child('price').get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if cache is stale
      final cachedAt = data['cachedAt'] as int?;
      if (cachedAt != null &&
          _isCacheStale(cachedAt, AppConstants.realTimePriceTTL)) {
        _logger.d('Crypto quote cache for $id is stale');
        return null;
      }

      return CryptoQuoteModel(
        id: data['id'] as String,
        symbol: data['symbol'] as String,
        name: data['name'] as String,
        currentPrice: (data['currentPrice'] as num).toDouble(),
        priceChange24h: (data['priceChange24h'] as num).toDouble(),
        priceChangePercentage24h:
            (data['priceChangePercentage24h'] as num).toDouble(),
        marketCap: (data['marketCap'] as num).toDouble(),
        marketCapRank: (data['marketCapRank'] as num).toInt(),
        totalVolume: (data['totalVolume'] as num).toDouble(),
        high24h: (data['high24h'] as num).toDouble(),
        low24h: (data['low24h'] as num).toDouble(),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          data['lastUpdated'] as int,
        ),
      );
    } catch (e) {
      _logger.e('Failed to get cached crypto quote from Firebase', error: e);
      return null;
    }
  }

  @override
  Future<void> cacheTechnicalIndicator(
    String symbol,
    String indicator,
    Map<String, dynamic> data,
  ) async {
    try {
      final cacheData = {
        ...data,
        'cachedAt': ServerValue.timestamp,
      };

      await _technicalIndicatorsRef
          .child(symbol)
          .child(indicator)
          .set(cacheData);

      _logger
          .d('Cached technical indicator $indicator for $symbol to Firebase');
    } catch (e) {
      _logger.e('Failed to cache technical indicator to Firebase', error: e);
      throw CacheException(
        message: 'Failed to cache technical indicator: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedTechnicalIndicator(
    String symbol,
    String indicator,
  ) async {
    try {
      final snapshot =
          await _technicalIndicatorsRef.child(symbol).child(indicator).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if cache is stale
      final cachedAt = data['cachedAt'] as int?;
      if (cachedAt != null &&
          _isCacheStale(cachedAt, AppConstants.technicalIndicatorsTTL)) {
        _logger.d('Technical indicator cache for $symbol/$indicator is stale');
        return null;
      }

      data.remove('cachedAt');
      return data;
    } catch (e) {
      _logger.e(
        'Failed to get cached technical indicator from Firebase',
        error: e,
      );
      return null;
    }
  }

  @override
  Stream<StockQuoteModel> watchStockQuote(String symbol) {
    return _stocksRef.child(symbol).child('quote').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw CacheException(
          message: 'No cached data for $symbol',
        );
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      return StockQuoteModel(
        symbol: data['symbol'] as String,
        price: (data['price'] as num).toDouble(),
        change: (data['change'] as num).toDouble(),
        changePercent: (data['changePercent'] as num).toDouble(),
        open: (data['open'] as num).toDouble(),
        high: (data['high'] as num).toDouble(),
        low: (data['low'] as num).toDouble(),
        previousClose: (data['previousClose'] as num).toDouble(),
        volume: (data['volume'] as num).toInt(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] as int,
        ),
      );
    });
  }

  @override
  Stream<CryptoQuoteModel> watchCryptoQuote(String id) {
    return _cryptoRef.child(id).child('price').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw CacheException(
          message: 'No cached data for $id',
        );
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      return CryptoQuoteModel(
        id: data['id'] as String,
        symbol: data['symbol'] as String,
        name: data['name'] as String,
        currentPrice: (data['currentPrice'] as num).toDouble(),
        priceChange24h: (data['priceChange24h'] as num).toDouble(),
        priceChangePercentage24h:
            (data['priceChangePercentage24h'] as num).toDouble(),
        marketCap: (data['marketCap'] as num).toDouble(),
        marketCapRank: (data['marketCapRank'] as num).toInt(),
        totalVolume: (data['totalVolume'] as num).toDouble(),
        high24h: (data['high24h'] as num).toDouble(),
        low24h: (data['low24h'] as num).toDouble(),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          data['lastUpdated'] as int,
        ),
      );
    });
  }

  @override
  Future<void> clearCache() async {
    try {
      await _marketDataRef.remove();
      _logger.i('Firebase cache cleared');
    } catch (e) {
      _logger.e('Failed to clear Firebase cache', error: e);
      throw CacheException(
        message: 'Failed to clear cache: $e',
      );
    }
  }

  /// Check if cache is stale based on TTL
  bool _isCacheStale(int cachedAtMs, int ttlSeconds) {
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    final now = DateTime.now();
    final difference = now.difference(cachedAt).inSeconds;
    return difference > ttlSeconds;
  }
}
