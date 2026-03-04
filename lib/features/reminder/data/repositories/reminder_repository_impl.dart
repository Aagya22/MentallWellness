import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/features/reminder/data/datasources/reminder_remote_datasource.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  final remote = ref.read(reminderRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return ReminderRepositoryImpl(remote: remote, networkInfo: networkInfo);
});

class ReminderRepositoryImpl implements IReminderRepository {
  final ReminderRemoteDatasource _remote;
  final INetworkInfo _networkInfo;

  ReminderRepositoryImpl({
    required ReminderRemoteDatasource remote,
    required INetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final models = await _remote.getReminders();
      final entities = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      return Right(entities);
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
  Future<Either<Failure, ReminderEntity>> createReminder({
    required String title,
    required String time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.createReminder(
        title: title,
        time: time,
        type: type,
        daysOfWeek: daysOfWeek,
        enabled: enabled,
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

  @override
  Future<Either<Failure, ReminderEntity>> updateReminder({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.updateReminder(
        id: id,
        title: title,
        time: time,
        type: type,
        daysOfWeek: daysOfWeek,
        enabled: enabled,
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

  @override
  Future<Either<Failure, Unit>> deleteReminder({required String id}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      await _remote.deleteReminder(id: id);
      return const Right(unit);
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
  Future<Either<Failure, ReminderEntity>> toggleReminder({required String id}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.toggleReminder(id: id);
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
  Future<Either<Failure, List<ReminderNotificationEntity>>> getNotificationHistory({int limit = 20}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final models = await _remote.getNotificationHistory(limit: limit);
      final entities = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
      return Right(entities);
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
  Future<Either<Failure, ReminderNotificationEntity>> markNotificationRead({required String id}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final model = await _remote.markNotificationRead(id: id);
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
  Future<Either<Failure, int>> markAllNotificationsRead() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final updated = await _remote.markAllNotificationsRead();
      return Right(updated);
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
  Future<Either<Failure, int>> clearNotificationHistory() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final deleted = await _remote.clearNotificationHistory();
      return Right(deleted);
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
  Future<Either<Failure, List<ReminderNotificationEntity>>> checkDueReminders({int windowMinutes = 2}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final models = await _remote.checkDueReminders(windowMinutes: windowMinutes);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
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
