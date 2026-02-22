import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';

abstract interface class IJournalRepository {
  Future<Either<Failure, List<JournalEntity>>> getJournals({String? q});
  Future<Either<Failure, JournalEntity>> createJournal({
    required String title,
    required String content,
    DateTime? date,
  });
  Future<Either<Failure, JournalEntity>> updateJournal({
    required String id,
    String? title,
    String? content,
    DateTime? date,
  });
  Future<Either<Failure, bool>> deleteJournal({required String id});
}
