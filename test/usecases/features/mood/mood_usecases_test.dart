import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_range_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';
import 'package:mentalwellness/features/mood/domain/usecases/create_mood_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/delete_mood_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_mood_overview_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_moods_range_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_moods_usecase.dart';

class _FakeMoodRepository implements IMoodRepository {
  Either<Failure, MoodOverviewEntity>? overviewResponse;
  Either<Failure, List<MoodEntity>>? moodsResponse;
  Either<Failure, List<MoodRangeEntity>>? moodsRangeResponse;
  Either<Failure, MoodEntity>? createResponse;
  Either<Failure, bool>? deleteResponse;

  int getOverviewCalls = 0;
  int getMoodsCalls = 0;
  int getMoodsInRangeCalls = 0;
  int createMoodCalls = 0;
  int deleteMoodCalls = 0;

  String? capturedFrom;
  String? capturedTo;
  int? capturedMood;
  String? capturedMoodType;
  String? capturedNote;
  DateTime? capturedDate;
  String? capturedDeleteId;

  @override
  Future<Either<Failure, MoodOverviewEntity>> getOverview() async {
    getOverviewCalls++;
    return overviewResponse ?? const Left(ApiFailure(message: 'overview not set'));
  }

  @override
  Future<Either<Failure, List<MoodEntity>>> getMoods() async {
    getMoodsCalls++;
    return moodsResponse ?? const Left(ApiFailure(message: 'moods not set'));
  }

  @override
  Future<Either<Failure, List<MoodRangeEntity>>> getMoodsInRange({
    required String from,
    required String to,
  }) async {
    getMoodsInRangeCalls++;
    capturedFrom = from;
    capturedTo = to;
    return moodsRangeResponse ?? const Left(ApiFailure(message: 'range not set'));
  }

  @override
  Future<Either<Failure, MoodEntity>> createMood({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  }) async {
    createMoodCalls++;
    capturedMood = mood;
    capturedMoodType = moodType;
    capturedNote = note;
    capturedDate = date;
    return createResponse ?? const Left(ApiFailure(message: 'create not set'));
  }

  @override
  Future<Either<Failure, bool>> deleteMood({required String id}) async {
    deleteMoodCalls++;
    capturedDeleteId = id;
    return deleteResponse ?? const Left(ApiFailure(message: 'delete not set'));
  }
}

void main() {
  late _FakeMoodRepository repository;

  late GetMoodOverviewUsecase getOverviewUsecase;
  late GetMoodsUsecase getMoodsUsecase;
  late GetMoodsRangeUsecase getMoodsRangeUsecase;
  late CreateMoodUsecase createMoodUsecase;
  late DeleteMoodUsecase deleteMoodUsecase;

  setUp(() {
    repository = _FakeMoodRepository();
    getOverviewUsecase = GetMoodOverviewUsecase(repository);
    getMoodsUsecase = GetMoodsUsecase(repository);
    getMoodsRangeUsecase = GetMoodsRangeUsecase(repository);
    createMoodUsecase = CreateMoodUsecase(repository);
    deleteMoodUsecase = DeleteMoodUsecase(repository);
  });

  test('GetMoodOverviewUsecase returns repository overview data', () async {
    final overview = MoodOverviewEntity(
      weekStart: DateTime(2026, 3, 2),
      days: const [],
      avgThisWeek: const MoodAverageEntity(score: 7.4, label: 'Good'),
      streak: 3,
      mostFrequent: const MoodMostFrequentEntity(key: 'Calm', count: 2),
    );
    repository.overviewResponse = Right(overview);

    final result = await getOverviewUsecase();

    expect(result, Right(overview));
    expect(repository.getOverviewCalls, 1);
  });

  test('GetMoodsUsecase returns repository moods list', () async {
    final moods = [
      MoodEntity(id: 'm1', mood: 8, moodType: 'Happy', date: DateTime(2026, 3, 8)),
    ];
    repository.moodsResponse = Right(moods);

    final result = await getMoodsUsecase();

    expect(result, Right(moods));
    expect(repository.getMoodsCalls, 1);
  });

  test('GetMoodsRangeUsecase forwards from and to values', () async {
    const from = '2026-03-01';
    const to = '2026-03-07';
    final range = [
      MoodRangeEntity(
        id: 'r1',
        dayKey: '2026-03-01',
        mood: 6,
        date: DateTime(2026, 3, 1, 8),
      ),
    ];
    repository.moodsRangeResponse = Right(range);

    final result = await getMoodsRangeUsecase(from: from, to: to);

    expect(result, Right(range));
    expect(repository.getMoodsInRangeCalls, 1);
    expect(repository.capturedFrom, from);
    expect(repository.capturedTo, to);
  });

  test('CreateMoodUsecase forwards all arguments to repository', () async {
    final date = DateTime(2026, 3, 8, 9, 30);
    final created = MoodEntity(
      id: 'm2',
      mood: 9,
      moodType: 'Joyful',
      note: 'Great morning run',
      date: date,
    );
    repository.createResponse = Right(created);

    final result = await createMoodUsecase(
      mood: 9,
      moodType: 'Joyful',
      note: 'Great morning run',
      date: date,
    );

    expect(result, Right(created));
    expect(repository.createMoodCalls, 1);
    expect(repository.capturedMood, 9);
    expect(repository.capturedMoodType, 'Joyful');
    expect(repository.capturedNote, 'Great morning run');
    expect(repository.capturedDate, date);
  });

  test('DeleteMoodUsecase forwards id and returns repository result', () async {
    const id = 'm3';
    repository.deleteResponse = const Right(true);

    final result = await deleteMoodUsecase(id: id);

    expect(result, const Right(true));
    expect(repository.deleteMoodCalls, 1);
    expect(repository.capturedDeleteId, id);
  });
}
