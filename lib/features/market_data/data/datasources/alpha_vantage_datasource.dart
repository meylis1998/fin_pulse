import 'package:fin_pulse/core/constants/api_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:fin_pulse/core/network/api_client.dart';
import 'package:fin_pulse/core/network/rate_limiter.dart';
import 'package:fin_pulse/features/market_data/data/models/stock_quote_model.dart';

/// Alpha Vantage API data source
///
/// Provides stock market data and 50+ technical indicators
/// Rate limit: 500 calls/day (25 calls/hour recommended)
abstract class AlphaVantageDataSource {
  Future<StockQuoteModel> getStockQuote(String symbol);
  Future<Map<String, dynamic>> getIntradayData(
    String symbol, {
    String interval = '5min',
  });
  Future<Map<String, dynamic>> getTechnicalIndicator(
    String symbol,
    String indicator, {
    Map<String, dynamic>? params,
  });
}

class AlphaVantageDataSourceImpl implements AlphaVantageDataSource {
  final ApiClient _apiClient;
  final RateLimiter _rateLimiter;

  AlphaVantageDataSourceImpl({
    required ApiClient apiClient,
    RateLimiter? rateLimiter,
  })  : _apiClient = apiClient,
        _rateLimiter = rateLimiter ??
            RateLimiterManager().getLimiter(
              'alpha_vantage',
              maxTokens: ApiConstants.alphaVantageRateLimit,
              refillPeriod: Duration(
                seconds: ApiConstants.alphaVantageRatePeriod,
              ),
            );

  @override
  Future<StockQuoteModel> getStockQuote(String symbol) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            ApiConstants.alphaVantageBaseUrl,
            queryParameters: {
              'function': 'GLOBAL_QUOTE',
              'symbol': symbol,
              'apikey': ApiConstants.alphaVantageApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(
                message: 'Empty response from Alpha Vantage');
          }

          final data = response.data as Map<String, dynamic>;

          // Check for API error messages
          if (data.containsKey('Error Message')) {
            throw ServerException(
              message: data['Error Message'],
            );
          }

          if (data.containsKey('Note')) {
            throw RateLimitException(
              message: 'Alpha Vantage rate limit exceeded',
              retryAfter: const Duration(minutes: 1),
            );
          }

          return StockQuoteModel.fromAlphaVantage(symbol, data);
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse stock quote: $e',
          );
        }
      },
      priority: RequestPriority.high,
    );
  }

  @override
  Future<Map<String, dynamic>> getIntradayData(
    String symbol, {
    String interval = '5min',
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            ApiConstants.alphaVantageBaseUrl,
            queryParameters: {
              'function': ApiConstants.avTimeSeriesIntraday,
              'symbol': symbol,
              'interval': interval,
              'apikey': ApiConstants.alphaVantageApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(
                message: 'Empty response from Alpha Vantage');
          }

          final data = response.data as Map<String, dynamic>;

          if (data.containsKey('Error Message')) {
            throw ServerException(message: data['Error Message']);
          }

          if (data.containsKey('Note')) {
            throw RateLimitException(
              message: 'Alpha Vantage rate limit exceeded',
              retryAfter: const Duration(minutes: 1),
            );
          }

          return data;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse intraday data: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }

  @override
  Future<Map<String, dynamic>> getTechnicalIndicator(
    String symbol,
    String indicator, {
    Map<String, dynamic>? params,
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final queryParams = {
            'function': indicator,
            'symbol': symbol,
            'interval': params?['interval'] ?? 'daily',
            'time_period': params?['time_period']?.toString() ?? '20',
            'series_type': params?['series_type'] ?? 'close',
            'apikey': ApiConstants.alphaVantageApiKey,
          };

          // Add optional parameters
          if (params != null) {
            params.forEach((key, value) {
              if (!queryParams.containsKey(key)) {
                queryParams[key] = value.toString();
              }
            });
          }

          final response = await _apiClient.get(
            ApiConstants.alphaVantageBaseUrl,
            queryParameters: queryParams,
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(
                message: 'Empty response from Alpha Vantage');
          }

          final data = response.data as Map<String, dynamic>;

          if (data.containsKey('Error Message')) {
            throw ServerException(message: data['Error Message']);
          }

          if (data.containsKey('Note')) {
            throw RateLimitException(
              message: 'Alpha Vantage rate limit exceeded',
              retryAfter: const Duration(minutes: 1),
            );
          }

          return data;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse technical indicator: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }
}
