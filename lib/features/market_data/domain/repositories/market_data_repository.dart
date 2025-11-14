import 'package:dartz/dartz.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/features/market_data/domain/entities/company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/entities/market_news.dart';
import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';

/// Market data repository interface
///
/// Defines contracts for fetching market data from various sources
/// Implementations handle caching strategy and error handling
abstract class MarketDataRepository {
  /// Get stock quote for a given symbol
  ///
  /// Returns cached data if available and fresh, otherwise fetches from API
  Future<Either<Failure, StockQuote>> getStockQuote(String symbol);

  /// Get cryptocurrency quote for a given id
  Future<Either<Failure, CryptoQuote>> getCryptoQuote(String id);

  /// Get multiple cryptocurrency quotes
  Future<Either<Failure, List<CryptoQuote>>> getCryptoQuotes({
    List<String>? ids,
    int limit = 100,
  });

  /// Get company profile/fundamentals
  Future<Either<Failure, CompanyProfile>> getCompanyProfile(String symbol);

  /// Get company news
  Future<Either<Failure, List<MarketNews>>> getCompanyNews(
    String symbol, {
    DateTime? from,
    DateTime? to,
  });

  /// Get intraday price data
  Future<Either<Failure, Map<String, dynamic>>> getIntradayData(
    String symbol, {
    String interval = '5min',
  });

  /// Get technical indicator data
  Future<Either<Failure, Map<String, dynamic>>> getTechnicalIndicator(
    String symbol,
    String indicator, {
    Map<String, dynamic>? params,
  });

  /// Stream real-time price updates via WebSocket
  Stream<Either<Failure, StockQuote>> streamRealTimePrice(String symbol);

  /// Subscribe to multiple real-time price feeds
  Future<Either<Failure, void>> subscribeToRealTimePrices(
    List<String> symbols,
  );

  /// Unsubscribe from real-time price feeds
  Future<Either<Failure, void>> unsubscribeFromRealTimePrices(
    List<String> symbols,
  );

  /// Clear all cached data
  Future<Either<Failure, void>> clearCache();
}
