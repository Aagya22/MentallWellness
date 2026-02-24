import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/domain/entities/guided_history_entity.dart';

abstract interface class IExerciseRepository {
  Future<Either<Failure, List<ExerciseEntity>>> getExercises();

  Future<Either<Failure, ExerciseEntity>> createExercise({
    required String type,
    required int duration,
    DateTime? date,
    String? notes,
  });

  Future<Either<Failure, ExerciseEntity>> completeGuidedExercise({
    required String title,
    required String category,
    required int plannedDurationSeconds,
    required int elapsedSeconds,
    DateTime? completedAt,
  });

  Future<Either<Failure, List<GuidedHistoryDayEntity>>> getGuidedHistory({
    DateTime? from,
    DateTime? to,
  });
}
