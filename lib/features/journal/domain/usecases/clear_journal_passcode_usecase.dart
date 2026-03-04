import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_passcode_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_passcode_repository.dart';

final clearJournalPasscodeUsecaseProvider =
    Provider<ClearJournalPasscodeUsecase>((ref) {
      return ClearJournalPasscodeUsecase(
        ref.read(journalPasscodeRepositoryProvider),
      );
    });

class ClearJournalPasscodeUsecase {
  final IJournalPasscodeRepository _repo;

  ClearJournalPasscodeUsecase(this._repo);

  Future<Either<Failure, bool>> call({required String password}) {
    return _repo.clearPasscode(password: password);
  }
}
