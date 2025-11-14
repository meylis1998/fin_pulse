import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for streaming real-time price updates via WebSocket
///
/// Provides sub-50ms latency updates for active trading
class StreamRealTimePrice {
  final MarketDataRepository repository;

  StreamRealTimePrice(this.repository);

  Stream<Either<Failure, StockQuote>> call(
    StreamRealTimePriceParams params,
  ) {
    return repository.streamRealTimePrice(params.symbol);
  }
}

class StreamRealTimePriceParams extends Equatable {
  final String symbol;

  const StreamRealTimePriceParams({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}
