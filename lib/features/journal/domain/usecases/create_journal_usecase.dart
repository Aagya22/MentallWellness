import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_repository.dart';

final createJournalUsecaseProvider = Provider<CreateJournalUsecase>((ref) {
  return CreateJournalUsecase(ref.read(journalRepositoryProvider));
});

class CreateJournalUsecase {
  final IJournalRepository _repo;

  CreateJournalUsecase(this._repo);

  Future<Either<Failure, JournalEntity>> call({
    required String title,
    required String content,
    DateTime? date,
  }) {
    return _repo.createJournal(title: title, content: content, date: date);
  }
}
