import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/features/mood/data/datasources/mood_remote_datasource.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final moodRepositoryProvider = Provider<IMoodRepository>((ref) {
  final remote = ref.read(moodRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return MoodRepositoryImpl(remote: remote, networkInfo: networkInfo);
});

class MoodRepositoryImpl implements IMoodRepository {
  final MoodRemoteDatasource _remote;
  final INetworkInfo _networkInfo;

  MoodRepositoryImpl({
    required MoodRemoteDatasource remote,
    required INetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, MoodOverviewEntity>> getOverview() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.getOverview();
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(ApiFailure(
        message: e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MoodEntity>>> getMoods() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final models = await _remote.getMoods();
      final list = models.map((m) => m.toEntity()).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return Right(list);
    } on DioException catch (e) {
      return Left(ApiFailure(
        message: e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MoodEntity>> createMood({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.createMood(
        mood: mood,
        moodType: moodType,
        note: note,
        date: date,
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(ApiFailure(
        message: e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
