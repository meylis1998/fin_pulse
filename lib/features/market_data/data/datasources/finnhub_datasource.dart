import 'package:fin_pulse/core/constants/api_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:fin_pulse/core/network/api_client.dart';
import 'package:fin_pulse/core/network/rate_limiter.dart';
import 'package:fin_pulse/features/market_data/data/models/stock_quote_model.dart';

/// Finnhub API data source
///
/// Provides company fundamentals, news, and earnings data
/// Rate limit: 60 calls/minute (free tier)
abstract class FinnhubDataSource {
  Future<StockQuoteModel> getStockQuote(String symbol);
  Future<Map<String, dynamic>> getCompanyProfile(String symbol);
  Future<List<Map<String, dynamic>>> getCompanyNews(
    String symbol, {
    DateTime? from,
    DateTime? to,
  });
  Future<List<Map<String, dynamic>>> getEarningsCalendar({
    DateTime? from,
    DateTime? to,
    String? symbol,
  });
  Future<Map<String, dynamic>> getBasicFinancials(String symbol);
}

class FinnhubDataSourceImpl implements FinnhubDataSource {
  final ApiClient _apiClient;
  final RateLimiter _rateLimiter;

  FinnhubDataSourceImpl({
    required ApiClient apiClient,
    RateLimiter? rateLimiter,
  })  : _apiClient = apiClient,
        _rateLimiter = rateLimiter ??
            RateLimiterManager().getLimiter(
              'finnhub',
              maxTokens: ApiConstants.finnhubRateLimit,
              refillPeriod: Duration(
                seconds: ApiConstants.finnhubRatePeriod,
              ),
            );

  @override
  Future<StockQuoteModel> getStockQuote(String symbol) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.finnhubBaseUrl}${ApiConstants.fhQuote}',
            queryParameters: {
              'symbol': symbol,
              'token': ApiConstants.finnhubApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from Finnhub');
          }

          final data = response.data as Map<String, dynamic>;

          // Check for error (Finnhub returns empty price on invalid symbol)
          if (data['c'] == 0 && data['d'] == 0 && data['dp'] == 0) {
            throw ServerException(
              message: 'Invalid symbol or no data available',
            );
          }

          return StockQuoteModel.fromFinnhub(symbol, data);
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
  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.finnhubBaseUrl}${ApiConstants.fhCompanyProfile}',
            queryParameters: {
              'symbol': symbol,
              'token': ApiConstants.finnhubApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from Finnhub');
          }

          final data = response.data as Map<String, dynamic>;

          // Check if company profile is empty
          if (data.isEmpty) {
            throw ServerException(
              message: 'Company profile not found for symbol: $symbol',
            );
          }

          return data;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse company profile: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyNews(
    String symbol, {
    DateTime? from,
    DateTime? to,
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final now = DateTime.now();
          final defaultFrom = from ?? now.subtract(const Duration(days: 7));
          final defaultTo = to ?? now;

          final response = await _apiClient.get(
            '${ApiConstants.finnhubBaseUrl}${ApiConstants.fhNews}',
            queryParameters: {
              'symbol': symbol,
              'from': _formatDate(defaultFrom),
              'to': _formatDate(defaultTo),
              'token': ApiConstants.finnhubApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from Finnhub');
          }

          return List<Map<String, dynamic>>.from(response.data as List);
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse company news: $e',
          );
        }
      },
      priority: RequestPriority.low,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getEarningsCalendar({
    DateTime? from,
    DateTime? to,
    String? symbol,
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final now = DateTime.now();
          final defaultFrom = from ?? now;
          final defaultTo = to ?? now.add(const Duration(days: 30));

          final queryParams = {
            'from': _formatDate(defaultFrom),
            'to': _formatDate(defaultTo),
            'token': ApiConstants.finnhubApiKey,
          };

          if (symbol != null) {
            queryParams['symbol'] = symbol;
          }

          final response = await _apiClient.get(
            '${ApiConstants.finnhubBaseUrl}${ApiConstants.fhEarningsCalendar}',
            queryParameters: queryParams,
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from Finnhub');
          }

          final data = response.data as Map<String, dynamic>;
          final earningsCalendar = data['earningsCalendar'] as List?;

          if (earningsCalendar == null) {
            return [];
          }

          return List<Map<String, dynamic>>.from(earningsCalendar);
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse earnings calendar: $e',
          );
        }
      },
      priority: RequestPriority.low,
    );
  }

  @override
  Future<Map<String, dynamic>> getBasicFinancials(String symbol) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.finnhubBaseUrl}/stock/metric',
            queryParameters: {
              'symbol': symbol,
              'metric': 'all',
              'token': ApiConstants.finnhubApiKey,
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from Finnhub');
          }

          return response.data as Map<String, dynamic>;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse basic financials: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }

  /// Format date as YYYY-MM-DD for Finnhub API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
