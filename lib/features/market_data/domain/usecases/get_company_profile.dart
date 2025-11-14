import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_pulse/core/errors/failures.dart';
import 'package:fin_pulse/core/usecases/usecase.dart';
import 'package:fin_pulse/features/market_data/domain/entities/company_profile.dart';
import 'package:fin_pulse/features/market_data/domain/repositories/market_data_repository.dart';

/// Use case for fetching company profile/fundamentals
class GetCompanyProfile
    implements UseCase<CompanyProfile, GetCompanyProfileParams> {
  final MarketDataRepository repository;

  GetCompanyProfile(this.repository);

  @override
  Future<Either<Failure, CompanyProfile>> call(
    GetCompanyProfileParams params,
  ) async {
    return await repository.getCompanyProfile(params.symbol);
  }
}

class GetCompanyProfileParams extends Equatable {
  final String symbol;

  const GetCompanyProfileParams({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}
