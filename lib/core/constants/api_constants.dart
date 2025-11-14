/// API Configuration Constants for FinPulse
class ApiConstants {
  // Base URLs
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String eodhdWebSocketUrl = 'wss://ws.eodhistoricaldata.com/ws';

  // API Keys (Should be loaded from environment variables in production)
  static const String alphaVantageApiKey = String.fromEnvironment(
    'ALPHA_VANTAGE_API_KEY',
    defaultValue: 'demo',
  );
  static const String finnhubApiKey = String.fromEnvironment(
    'FINNHUB_API_KEY',
    defaultValue: 'demo',
  );
  static const String eodhdApiKey = String.fromEnvironment(
    'EODHD_API_KEY',
    defaultValue: 'demo',
  );

  // Rate Limits (requests per period)
  static const int alphaVantageRateLimit = 500; // 500 calls/day
  static const int alphaVantageRatePeriod = 86400; // 24 hours in seconds
  static const int coinGeckoRateLimit = 50; // 50 calls/minute
  static const int coinGeckoRatePeriod = 60; // 1 minute in seconds
  static const int finnhubRateLimit = 60; // 60 calls/minute
  static const int finnhubRatePeriod = 60; // 1 minute in seconds

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 5);

  // Alpha Vantage Endpoints
  static const String avTimeSeriesIntraday = 'TIME_SERIES_INTRADAY';
  static const String avTimeSeriesDaily = 'TIME_SERIES_DAILY';
  static const String avSMA = 'SMA';
  static const String avEMA = 'EMA';
  static const String avRSI = 'RSI';
  static const String avMACD = 'MACD';
  static const String avBBANDS = 'BBANDS';

  // CoinGecko Endpoints
  static const String cgCoinsMarkets = '/coins/markets';
  static const String cgCoinDetail = '/coins';
  static const String cgMarketChart = '/market_chart';
  static const String cgTrending = '/search/trending';

  // Finnhub Endpoints
  static const String fhQuote = '/quote';
  static const String fhCompanyProfile = '/stock/profile2';
  static const String fhNews = '/company-news';
  static const String fhEarningsCalendar = '/calendar/earnings';

  // WebSocket Events
  static const String wsSubscribe = 'subscribe';
  static const String wsUnsubscribe = 'unsubscribe';
  static const String wsPriceUpdate = 'price_update';
}
