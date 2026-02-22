import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_repository.dart';

final updateJournalUsecaseProvider = Provider<UpdateJournalUsecase>((ref) {
  return UpdateJournalUsecase(ref.read(journalRepositoryProvider));
});

class UpdateJournalUsecase {
  final IJournalRepository _repo;

  UpdateJournalUsecase(this._repo);

  Future<Either<Failure, JournalEntity>> call({
    required String id,
    String? title,
    String? content,
    DateTime? date,
  }) {
    return _repo.updateJournal(id: id, title: title, content: content, date: date);
  }
}
