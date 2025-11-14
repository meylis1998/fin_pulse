import 'package:fin_pulse/core/constants/api_constants.dart';
import 'package:fin_pulse/core/errors/exceptions.dart';
import 'package:fin_pulse/core/network/api_client.dart';
import 'package:fin_pulse/core/network/rate_limiter.dart';

/// CoinGecko API data source
///
/// Provides cryptocurrency market data for 10,000+ coins
/// Rate limit: 50 calls/minute (free tier)
abstract class CoinGeckoDataSource {
  Future<List<Map<String, dynamic>>> getCoinsMarkets({
    String vsCurrency = 'usd',
    List<String>? ids,
    int perPage = 100,
    int page = 1,
  });
  Future<Map<String, dynamic>> getCoinData(String id);
  Future<Map<String, dynamic>> getMarketChart(
    String id, {
    String vsCurrency = 'usd',
    int days = 7,
  });
  Future<Map<String, dynamic>> getTrending();
}

class CoinGeckoDataSourceImpl implements CoinGeckoDataSource {
  final ApiClient _apiClient;
  final RateLimiter _rateLimiter;

  CoinGeckoDataSourceImpl({
    required ApiClient apiClient,
    RateLimiter? rateLimiter,
  })  : _apiClient = apiClient,
        _rateLimiter = rateLimiter ??
            RateLimiterManager().getLimiter(
              'coingecko',
              maxTokens: ApiConstants.coinGeckoRateLimit,
              refillPeriod: Duration(
                seconds: ApiConstants.coinGeckoRatePeriod,
              ),
            );

  @override
  Future<List<Map<String, dynamic>>> getCoinsMarkets({
    String vsCurrency = 'usd',
    List<String>? ids,
    int perPage = 100,
    int page = 1,
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final queryParams = {
            'vs_currency': vsCurrency,
            'per_page': perPage.toString(),
            'page': page.toString(),
            'sparkline': 'false',
          };

          if (ids != null && ids.isNotEmpty) {
            queryParams['ids'] = ids.join(',');
          }

          final response = await _apiClient.get(
            '${ApiConstants.coinGeckoBaseUrl}${ApiConstants.cgCoinsMarkets}',
            queryParameters: queryParams,
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from CoinGecko');
          }

          return List<Map<String, dynamic>>.from(response.data as List);
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse coins markets: $e',
          );
        }
      },
      priority: RequestPriority.high,
    );
  }

  @override
  Future<Map<String, dynamic>> getCoinData(String id) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.coinGeckoBaseUrl}${ApiConstants.cgCoinDetail}/$id',
            queryParameters: {
              'localization': 'false',
              'tickers': 'false',
              'community_data': 'false',
              'developer_data': 'false',
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from CoinGecko');
          }

          return response.data as Map<String, dynamic>;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse coin data: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }

  @override
  Future<Map<String, dynamic>> getMarketChart(
    String id, {
    String vsCurrency = 'usd',
    int days = 7,
  }) async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.coinGeckoBaseUrl}${ApiConstants.cgCoinDetail}/$id${ApiConstants.cgMarketChart}',
            queryParameters: {
              'vs_currency': vsCurrency,
              'days': days.toString(),
            },
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from CoinGecko');
          }

          return response.data as Map<String, dynamic>;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse market chart: $e',
          );
        }
      },
      priority: RequestPriority.normal,
    );
  }

  @override
  Future<Map<String, dynamic>> getTrending() async {
    return _rateLimiter.execute(
      function: () async {
        try {
          final response = await _apiClient.get(
            '${ApiConstants.coinGeckoBaseUrl}${ApiConstants.cgTrending}',
            timeout: ApiConstants.apiTimeout,
          );

          if (response.data == null) {
            throw ParsingException(message: 'Empty response from CoinGecko');
          }

          return response.data as Map<String, dynamic>;
        } catch (e) {
          if (e is AppException) rethrow;
          throw ParsingException(
            message: 'Failed to parse trending data: $e',
          );
        }
      },
      priority: RequestPriority.low,
    );
  }
}
