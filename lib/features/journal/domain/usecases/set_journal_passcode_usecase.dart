import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_passcode_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_passcode_repository.dart';

final setJournalPasscodeUsecaseProvider = Provider<SetJournalPasscodeUsecase>((
  ref,
) {
  return SetJournalPasscodeUsecase(ref.read(journalPasscodeRepositoryProvider));
});

class SetJournalPasscodeUsecase {
  final IJournalPasscodeRepository _repo;

  SetJournalPasscodeUsecase(this._repo);

  Future<Either<Failure, bool>> call({
    required String passcode,
    required String password,
  }) {
    return _repo.setPasscode(passcode: passcode, password: password);
  }
}
