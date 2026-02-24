import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_range_entity.dart';

abstract interface class IMoodRepository {
  Future<Either<Failure, MoodOverviewEntity>> getOverview();
  Future<Either<Failure, List<MoodEntity>>> getMoods();
  Future<Either<Failure, List<MoodRangeEntity>>> getMoodsInRange({
    required String from,
    required String to,
  });
  Future<Either<Failure, MoodEntity>> createMood({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  });
}
