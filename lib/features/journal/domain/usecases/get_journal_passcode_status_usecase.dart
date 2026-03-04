import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_passcode_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_passcode_repository.dart';

final getJournalPasscodeStatusUsecaseProvider =
    Provider<GetJournalPasscodeStatusUsecase>((ref) {
      return GetJournalPasscodeStatusUsecase(
        ref.read(journalPasscodeRepositoryProvider),
      );
    });

class GetJournalPasscodeStatusUsecase {
  final IJournalPasscodeRepository _repo;

  GetJournalPasscodeStatusUsecase(this._repo);

  Future<Either<Failure, bool>> call() {
    return _repo.getStatus();
  }
}
