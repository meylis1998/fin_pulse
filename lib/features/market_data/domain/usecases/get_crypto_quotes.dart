import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/usecases/usecase.dart';
import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for fetching multiple cryptocurrency quotes
class GetCryptoQuotes
    implements UseCase<List<CryptoQuote>, GetCryptoQuotesParams> {
  final MarketDataRepository repository;

  GetCryptoQuotes(this.repository);

  @override
  Future<Either<Failure, List<CryptoQuote>>> call(
    GetCryptoQuotesParams params,
  ) async {
    return await repository.getCryptoQuotes(
      ids: params.ids,
      limit: params.limit,
    );
  }
}

class GetCryptoQuotesParams extends Equatable {
  final List<String>? ids;
  final int limit;

  const GetCryptoQuotesParams({
    this.ids,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [ids, limit];
}
