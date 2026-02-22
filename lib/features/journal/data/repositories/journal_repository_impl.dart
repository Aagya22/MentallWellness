import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/features/journal/data/datasources/journal_remote_datasource.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<IJournalRepository>((ref) {
  final remote = ref.read(journalRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return JournalRepositoryImpl(remote: remote, networkInfo: networkInfo);
});

class JournalRepositoryImpl implements IJournalRepository {
  final JournalRemoteDatasource _remote;
  final INetworkInfo _networkInfo;

  JournalRepositoryImpl({
    required JournalRemoteDatasource remote,
    required INetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, List<JournalEntity>>> getJournals({String? q}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final models = await _remote.getJournals(q: q);
      return Right(models.map((m) => m.toEntity()).toList());
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
  Future<Either<Failure, JournalEntity>> createJournal({
    required String title,
    required String content,
    DateTime? date,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.createJournal(
        title: title,
        content: content,
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

  @override
  Future<Either<Failure, JournalEntity>> updateJournal({
    required String id,
    String? title,
    String? content,
    DateTime? date,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      final model = await _remote.updateJournal(
        id: id,
        title: title,
        content: content,
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

  @override
  Future<Either<Failure, bool>> deleteJournal({required String id}) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }
      await _remote.deleteJournal(id: id);
      return const Right(true);
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
