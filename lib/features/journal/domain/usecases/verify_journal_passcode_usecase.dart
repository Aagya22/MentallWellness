import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_passcode_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_passcode_repository.dart';

final verifyJournalPasscodeUsecaseProvider =
    Provider<VerifyJournalPasscodeUsecase>((ref) {
      return VerifyJournalPasscodeUsecase(
        ref.read(journalPasscodeRepositoryProvider),
      );
    });

class VerifyJournalPasscodeUsecase {
  final IJournalPasscodeRepository _repo;

  VerifyJournalPasscodeUsecase(this._repo);

  Future<Either<Failure, bool>> call({required String passcode}) {
    return _repo.verifyPasscode(passcode: passcode);
  }
}
