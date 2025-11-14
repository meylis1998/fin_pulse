import 'package:dartz/dartz.dart';
import 'package:fin_pulse/core/errors/failures.dart';

/// Base class for all use cases
///
/// [Type] - The return type of the use case
/// [Params] - The parameters required by the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
class NoParams {
  const NoParams();
}
