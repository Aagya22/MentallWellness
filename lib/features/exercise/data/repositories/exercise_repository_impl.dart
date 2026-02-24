import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/features/exercise/data/datasources/exercise_remote_datasource.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/domain/entities/guided_history_entity.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<IExerciseRepository>((ref) {
  final remote = ref.read(exerciseRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return ExerciseRepositoryImpl(remote: remote, networkInfo: networkInfo);
});

class ExerciseRepositoryImpl implements IExerciseRepository {
  final ExerciseRemoteDatasource _remote;
  final INetworkInfo _networkInfo;

  ExerciseRepositoryImpl({
    required ExerciseRemoteDatasource remote,
    required INetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, List<ExerciseEntity>>> getExercises() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final models = await _remote.getExercises();
      final entities = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(entities);
    } on DioException catch (e) {
      return Left(ApiFailure(
        message:
            e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExerciseEntity>> createExercise({
    required String type,
    required int duration,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.createExercise(
        type: type,
        duration: duration,
        date: date,
        notes: notes,
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(ApiFailure(
        message:
            e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExerciseEntity>> completeGuidedExercise({
    required String title,
    required String category,
    required int plannedDurationSeconds,
    required int elapsedSeconds,
    DateTime? completedAt,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.completeGuidedExercise(
        title: title,
        category: category,
        plannedDurationSeconds: plannedDurationSeconds,
        elapsedSeconds: elapsedSeconds,
        completedAt: completedAt,
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(ApiFailure(
        message:
            e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GuidedHistoryDayEntity>>> getGuidedHistory({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final models = await _remote.getGuidedHistory(from: from, to: to);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on DioException catch (e) {
      return Left(ApiFailure(
        message:
            e.response?.data?['message']?.toString() ?? e.message ?? 'API error',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
