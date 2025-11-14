import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/usecases/usecase.dart';
import 'package:fin_pulse/features/market_data/domain/entities/crypto_quote.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for fetching cryptocurrency quote
class GetCryptoQuote implements UseCase<CryptoQuote, GetCryptoQuoteParams> {
  final MarketDataRepository repository;

  GetCryptoQuote(this.repository);

  @override
  Future<Either<Failure, CryptoQuote>> call(
    GetCryptoQuoteParams params,
  ) async {
    return await repository.getCryptoQuote(params.id);
  }
}

class GetCryptoQuoteParams extends Equatable {
  final String id; // CoinGecko ID (e.g., 'bitcoin')

  const GetCryptoQuoteParams({required this.id});

  @override
  List<Object?> get props => [id];
}
