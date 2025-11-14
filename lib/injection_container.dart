import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fin_pulse/core/network/api_client.dart';
import 'package:fin_pulse/core/network/network_info.dart';
import 'package:fin_pulse/core/network/rate_limiter.dart';
import 'package:fin_pulse/features/market_data/data/datasources/alpha_vantage_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/coingecko_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/eodhd_websocket_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/finnhub_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/firebase_cache_datasource.dart';
import 'package:fin_pulse/features/market_data/data/datasources/hive_cache_datasource.dart';
import 'package:fin_pulse/features/market_data/data/repositories/market_data_repository_impl.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_crypto_quotes.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_stock_quote.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/get_technical_indicator.dart';
import 'package:fin_pulse/features/market_data/domain/usecases/stream_real_time_price.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_bloc.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

final sl = GetIt.instance; // Service Locator

/// Initialize dependency injection
Future<void> initializeDependencies() async {
  // ========== Core ==========

  // API Client
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(dio: sl()));

  // Network Info
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  // Rate Limiter Manager (Singleton)
  sl.registerLazySingleton<RateLimiterManager>(() => RateLimiterManager());

  // ========== Data Sources ==========

  // Remote Data Sources
  sl.registerLazySingleton<AlphaVantageDataSource>(
    () => AlphaVantageDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<CoinGeckoDataSource>(
    () => CoinGeckoDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<FinnhubDataSource>(
    () => FinnhubDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<EodhdWebSocketDataSource>(
    () => EodhdWebSocketDataSourceImpl(),
  );

  // Cache Data Sources
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);
  sl.registerLazySingleton<FirebaseCacheDataSource>(
    () => FirebaseCacheDataSourceImpl(database: sl()),
  );

  // Hive initialization and cache data source
  await Hive.initFlutter();
  final hiveCache = HiveCacheDataSourceImpl();
  await hiveCache.init();
  sl.registerLazySingleton<HiveCacheDataSource>(() => hiveCache);

  // ========== Repositories ==========

  sl.registerLazySingleton<MarketDataRepository>(
    () => MarketDataRepositoryImpl(
      alphaVantageDataSource: sl(),
      coinGeckoDataSource: sl(),
      finnhubDataSource: sl(),
      websocketDataSource: sl(),
      firebaseCache: sl(),
      hiveCache: sl(),
      networkInfo: sl(),
    ),
  );

  // ========== Use Cases ==========

  // Stock use cases
  sl.registerLazySingleton(() => GetStockQuote(sl()));
  sl.registerLazySingleton(() => StreamRealTimePrice(sl()));
  sl.registerLazySingleton(() => GetCompanyProfile(sl()));
  sl.registerLazySingleton(() => GetTechnicalIndicator(sl()));

  // Crypto use cases
  sl.registerLazySingleton(() => GetCryptoQuote(sl()));
  sl.registerLazySingleton(() => GetCryptoQuotes(sl()));

  // ========== BLoC / Cubits ==========

  // Market Data BLoC
  sl.registerFactory(
    () => MarketDataBloc(
      getStockQuote: sl(),
      getCryptoQuote: sl(),
      getCryptoQuotes: sl(),
      getCompanyProfile: sl(),
      getTechnicalIndicator: sl(),
      streamRealTimePrice: sl(),
    ),
  );

  // Watchlist BLoC
  sl.registerFactory(() => WatchlistBloc());
}
