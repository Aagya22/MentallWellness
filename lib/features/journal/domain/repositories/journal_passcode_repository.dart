import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';

abstract interface class IJournalPasscodeRepository {
  Future<Either<Failure, bool>> getStatus();

  Future<Either<Failure, bool>> setPasscode({
    required String passcode,
    required String password,
  });

  Future<Either<Failure, bool>> clearPasscode({required String password});

  /// Verifies passcode and stores a short-lived journal access token.
  Future<Either<Failure, bool>> verifyPasscode({required String passcode});
}
