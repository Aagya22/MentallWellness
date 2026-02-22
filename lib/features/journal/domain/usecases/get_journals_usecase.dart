import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_repository.dart';

final getJournalsUsecaseProvider = Provider<GetJournalsUsecase>((ref) {
  return GetJournalsUsecase(ref.read(journalRepositoryProvider));
});

class GetJournalsUsecase {
  final IJournalRepository _repo;

  GetJournalsUsecase(this._repo);

  Future<Either<Failure, List<JournalEntity>>> call({String? q}) {
    return _repo.getJournals(q: q);
  }
}
