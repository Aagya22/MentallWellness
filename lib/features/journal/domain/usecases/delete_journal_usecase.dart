import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_repository.dart';

final deleteJournalUsecaseProvider = Provider<DeleteJournalUsecase>((ref) {
  return DeleteJournalUsecase(ref.read(journalRepositoryProvider));
});

class DeleteJournalUsecase {
  final IJournalRepository _repo;

  DeleteJournalUsecase(this._repo);

  Future<Either<Failure, bool>> call({required String id}) {
    return _repo.deleteJournal(id: id);
  }
}
