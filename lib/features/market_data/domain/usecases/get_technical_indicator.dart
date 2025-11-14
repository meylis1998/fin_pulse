import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/usecases/usecase.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for fetching technical indicators (SMA, EMA, RSI, MACD, etc.)
class GetTechnicalIndicator
    implements UseCase<Map<String, dynamic>, GetTechnicalIndicatorParams> {
  final MarketDataRepository repository;

  GetTechnicalIndicator(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetTechnicalIndicatorParams params,
  ) async {
    return await repository.getTechnicalIndicator(
      params.symbol,
      params.indicator,
      params: params.params,
    );
  }
}

class GetTechnicalIndicatorParams extends Equatable {
  final String symbol;
  final String indicator; // SMA, EMA, RSI, MACD, BBANDS, etc.
  final Map<String, dynamic>? params; // Period, series type, etc.

  const GetTechnicalIndicatorParams({
    required this.symbol,
    required this.indicator,
    this.params,
  });

  @override
  List<Object?> get props => [symbol, indicator, params];
}
