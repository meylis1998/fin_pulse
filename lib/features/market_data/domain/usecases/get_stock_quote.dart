import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/usecases/usecase.dart';
import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for fetching stock quote
///
/// Implements caching strategy:
/// 1. Check memory cache
/// 2. Check local cache (Hive)
/// 3. Check cloud cache (Firebase)
/// 4. Fetch from API
class GetStockQuote implements UseCase<StockQuote, GetStockQuoteParams> {
  final MarketDataRepository repository;

  GetStockQuote(this.repository);

  @override
  Future<Either<Failure, StockQuote>> call(GetStockQuoteParams params) async {
    return await repository.getStockQuote(params.symbol);
  }
}

class GetStockQuoteParams extends Equatable {
  final String symbol;

  const GetStockQuoteParams({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}
