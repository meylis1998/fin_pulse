import 'package:fin_pulse/core/constants/app_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

/// Cached data wrapper with timestamp
class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final int ttl; // Time to live in seconds

  CachedData({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(cachedAt).inSeconds;
    return difference > ttl;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.millisecondsSinceEpoch,
        'ttl': ttl,
      };

  factory CachedData.fromJson(Map<String, dynamic> json, T data) {
    return CachedData(
      data: data,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      ttl: json['ttl'] as int,
    );
  }
}

/// Hive local cache data source
///
/// Layer 2 caching: Local persistent storage for offline-first functionality
/// Use for user portfolios, preferences, and frequently accessed data
abstract class HiveCacheDataSource {
  Future<void> init();
  Future<void> cacheStockQuote(String symbol, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCachedStockQuote(String symbol);
  Future<void> cacheCryptoQuote(String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCachedCryptoQuote(String id);
  Future<void> cacheUserPortfolio(String userId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getUserPortfolio(String userId);
  Future<void> cacheWatchlist(String userId, List<String> symbols);
  Future<List<String>?> getWatchlist(String userId);
  Future<void> clearCache();
}

class HiveCacheDataSourceImpl implements HiveCacheDataSource {
  final Logger _logger = Logger();

  // Box names
  static const String _stockQuotesBox = 'stock_quotes';
  static const String _cryptoQuotesBox = 'crypto_quotes';
  static const String _portfoliosBox = 'portfolios';
  static const String _watchlistsBox = 'watchlists';
  static const String _preferencesBox = 'preferences';

  Box? _stockQuotes;
  Box? _cryptoQuotes;
  Box? _portfolios;
  Box? _watchlists;
  Box? _preferences;

  @override
  Future<void> init() async {
    try {
      _logger.i('Initializing Hive cache...');

      // Open all boxes
      _stockQuotes = await Hive.openBox(_stockQuotesBox);
      _cryptoQuotes = await Hive.openBox(_cryptoQuotesBox);
      _portfolios = await Hive.openBox(_portfoliosBox);
      _watchlists = await Hive.openBox(_watchlistsBox);
      _preferences = await Hive.openBox(_preferencesBox);

      _logger.i('Hive cache initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Hive cache', error: e);
      throw CacheException(
        message: 'Failed to initialize Hive: $e',
      );
    }
  }

  @override
  Future<void> cacheStockQuote(
    String symbol,
    Map<String, dynamic> data,
  ) async {
    try {
      _ensureInitialized();

      final cachedData = CachedData(
        data: data,
        cachedAt: DateTime.now(),
        ttl: AppConstants.realTimePriceTTL,
      );

      await _stockQuotes!.put(symbol, cachedData.toJson());

      _logger.d('Cached stock quote for $symbol to Hive');
    } catch (e) {
      _logger.e('Failed to cache stock quote to Hive', error: e);
      throw CacheException(
        message: 'Failed to cache stock quote: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedStockQuote(String symbol) async {
    try {
      _ensureInitialized();

      final cachedJson = _stockQuotes!.get(symbol) as Map<dynamic, dynamic>?;

      if (cachedJson == null) {
        return null;
      }

      final cached = CachedData.fromJson(
        Map<String, dynamic>.from(cachedJson),
        Map<String, dynamic>.from(cachedJson['data'] as Map),
      );

      if (cached.isStale) {
        _logger.d('Stock quote cache for $symbol is stale');
        await _stockQuotes!.delete(symbol);
        return null;
      }

      return cached.data;
    } catch (e) {
      _logger.e('Failed to get cached stock quote from Hive', error: e);
      return null;
    }
  }

  @override
  Future<void> cacheCryptoQuote(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      _ensureInitialized();

      final cachedData = CachedData(
        data: data,
        cachedAt: DateTime.now(),
        ttl: AppConstants.realTimePriceTTL,
      );

      await _cryptoQuotes!.put(id, cachedData.toJson());

      _logger.d('Cached crypto quote for $id to Hive');
    } catch (e) {
      _logger.e('Failed to cache crypto quote to Hive', error: e);
      throw CacheException(
        message: 'Failed to cache crypto quote: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedCryptoQuote(String id) async {
    try {
      _ensureInitialized();

      final cachedJson = _cryptoQuotes!.get(id) as Map<dynamic, dynamic>?;

      if (cachedJson == null) {
        return null;
      }

      final cached = CachedData.fromJson(
        Map<String, dynamic>.from(cachedJson),
        Map<String, dynamic>.from(cachedJson['data'] as Map),
      );

      if (cached.isStale) {
        _logger.d('Crypto quote cache for $id is stale');
        await _cryptoQuotes!.delete(id);
        return null;
      }

      return cached.data;
    } catch (e) {
      _logger.e('Failed to get cached crypto quote from Hive', error: e);
      return null;
    }
  }

  @override
  Future<void> cacheUserPortfolio(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      _ensureInitialized();

      // Portfolios don't expire, so no TTL
      await _portfolios!.put(userId, data);

      _logger.d('Cached portfolio for user $userId to Hive');
    } catch (e) {
      _logger.e('Failed to cache portfolio to Hive', error: e);
      throw CacheException(
        message: 'Failed to cache portfolio: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserPortfolio(String userId) async {
    try {
      _ensureInitialized();

      final data = _portfolios!.get(userId) as Map<dynamic, dynamic>?;

      if (data == null) {
        return null;
      }

      return Map<String, dynamic>.from(data);
    } catch (e) {
      _logger.e('Failed to get portfolio from Hive', error: e);
      return null;
    }
  }

  @override
  Future<void> cacheWatchlist(String userId, List<String> symbols) async {
    try {
      _ensureInitialized();

      await _watchlists!.put(userId, symbols);

      _logger.d('Cached watchlist for user $userId to Hive');
    } catch (e) {
      _logger.e('Failed to cache watchlist to Hive', error: e);
      throw CacheException(
        message: 'Failed to cache watchlist: $e',
      );
    }
  }

  @override
  Future<List<String>?> getWatchlist(String userId) async {
    try {
      _ensureInitialized();

      final data = _watchlists!.get(userId) as List<dynamic>?;

      if (data == null) {
        return null;
      }

      return List<String>.from(data);
    } catch (e) {
      _logger.e('Failed to get watchlist from Hive', error: e);
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _ensureInitialized();

      await _stockQuotes!.clear();
      await _cryptoQuotes!.clear();
      await _portfolios!.clear();
      await _watchlists!.clear();
      await _preferences!.clear();

      _logger.i('Hive cache cleared');
    } catch (e) {
      _logger.e('Failed to clear Hive cache', error: e);
      throw CacheException(
        message: 'Failed to clear cache: $e',
      );
    }
  }

  /// Ensure Hive is initialized before operations
  void _ensureInitialized() {
    if (_stockQuotes == null ||
        _cryptoQuotes == null ||
        _portfolios == null ||
        _watchlists == null ||
        _preferences == null) {
      throw CacheException(
        message: 'Hive not initialized. Call init() first.',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _stockQuotes?.close();
    await _cryptoQuotes?.close();
    await _portfolios?.close();
    await _watchlists?.close();
    await _preferences?.close();
  }
}
