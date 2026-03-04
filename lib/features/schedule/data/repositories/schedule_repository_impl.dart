import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/domain/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  final remote = ref.read(scheduleRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return ScheduleRepositoryImpl(remote: remote, networkInfo: networkInfo);
});

class ScheduleRepositoryImpl implements IScheduleRepository {
  final ScheduleRemoteDatasource _remote;
  final INetworkInfo _networkInfo;

  ScheduleRepositoryImpl({
    required ScheduleRemoteDatasource remote,
    required INetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    String? q,
    String? from,
    String? to,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final models = await _remote.getSchedules(q: q, from: from, to: to);
      final entities = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final adt = '${a.date} ${a.time}';
          final bdt = '${b.date} ${b.time}';
          return adt.compareTo(bdt);
        });
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
  Future<Either<Failure, ScheduleEntity>> createSchedule({
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.createSchedule(
        title: title,
        date: date,
        time: time,
        description: description,
        location: location,
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
  Future<Either<Failure, ScheduleEntity>> updateSchedule({
    required String id,
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.updateSchedule(
        id: id,
        title: title,
        date: date,
        time: time,
        description: description,
        location: location,
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
  Future<Either<Failure, Unit>> deleteSchedule({
    required String id,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      await _remote.deleteSchedule(id: id);
      return const Right(unit);
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
