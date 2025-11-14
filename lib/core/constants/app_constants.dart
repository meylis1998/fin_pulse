/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'FinPulse';
  static const String appVersion = '1.0.0';

  // Cache TTL (Time To Live) in seconds
  static const int realTimePriceTTL = 10; // 10 seconds
  static const int dailyDataMarketHoursTTL = 3600; // 1 hour
  static const int dailyDataAfterHoursTTL = 86400; // 24 hours
  static const int technicalIndicatorsTTL = 300; // 5 minutes
  static const int companyFundamentalsTTL = 86400; // 24 hours
  static const int newsTTL = 1800; // 30 minutes

  // Default tickers for watchlist
  static const List<String> defaultStockTickers = [
    'AAPL',
    'MSFT',
    'GOOGL',
    'TSLA',
    'AMZN',
  ];

  static const List<String> defaultCryptoTickers = [
    'bitcoin',
    'ethereum',
    'binancecoin',
    'cardano',
    'solana',
  ];

  // Chart configurations
  static const int defaultCandleCount = 100;
  static const List<String> timeframes = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];

  // Technical Indicator default parameters
  static const int smaShortPeriod = 20;
  static const int smaMediumPeriod = 50;
  static const int smaLongPeriod = 200;
  static const int emaShortPeriod = 12;
  static const int emaLongPeriod = 26;
  static const int rsiPeriod = 14;
  static const int macdFastPeriod = 12;
  static const int macdSlowPeriod = 26;
  static const int macdSignalPeriod = 9;
  static const int bollingerBandsPeriod = 20;
  static const double bollingerBandsStdDev = 2.0;

  // Firebase paths
  static const String marketDataPath = 'market_data';
  static const String stocksPath = 'stocks';
  static const String cryptoPath = 'crypto';
  static const String technicalIndicatorsPath = 'technical_indicators';
  static const String userDataPath = 'user_data';
  static const String portfoliosPath = 'portfolios';
  static const String watchlistsPath = 'watchlists';
  static const String alertsPath = 'alerts';

  // Pusher configuration
  static const String pusherAppKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: 'demo',
  );
  static const String pusherCluster = 'us2';

  // Notification channels
  static const String priceAlertChannelId = 'price_alerts';
  static const String newsAlertChannelId = 'news_alerts';
  static const String earningsAlertChannelId = 'earnings_alerts';

  // Error messages
  static const String networkErrorMessage = 'Network connection failed';
  static const String rateLimitErrorMessage =
      'Rate limit exceeded. Please try again later';
  static const String authErrorMessage = 'Authentication failed';
  static const String unknownErrorMessage = 'An unexpected error occurred';
}
