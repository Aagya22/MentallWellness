import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/core/services/storage/journal_access_token_service.dart';
import 'package:mentalwellness/features/journal/data/datasources/journal_passcode_remote_datasource.dart';
import 'package:mentalwellness/features/journal/domain/repositories/journal_passcode_repository.dart';

final journalPasscodeRepositoryProvider = Provider<IJournalPasscodeRepository>((
  ref,
) {
  final remote = ref.read(journalPasscodeRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  final journalAccessTokenService = ref.read(journalAccessTokenServiceProvider);

  return JournalPasscodeRepositoryImpl(
    remote: remote,
    networkInfo: networkInfo,
    journalAccessTokenService: journalAccessTokenService,
  );
});

class JournalPasscodeRepositoryImpl implements IJournalPasscodeRepository {
  final JournalPasscodeRemoteDatasource _remote;
  final INetworkInfo _networkInfo;
  final JournalAccessTokenService _journalAccessTokenService;

  JournalPasscodeRepositoryImpl({
    required JournalPasscodeRemoteDatasource remote,
    required INetworkInfo networkInfo,
    required JournalAccessTokenService journalAccessTokenService,
  }) : _remote = remote,
       _networkInfo = networkInfo,
       _journalAccessTokenService = journalAccessTokenService;

  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, bool>> getStatus() async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final enabled = await _remote.getStatus();
      return Right(enabled);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message:
              e.response?.data?['message']?.toString() ??
              e.message ??
              'API error',
          statusCode: e.response?.statusCode,
          code: e.response?.data?['code']?.toString(),
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setPasscode({
    required String passcode,
    required String password,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final enabled = await _remote.setPasscode(
        passcode: passcode,
        password: password,
      );

      try {
        await _journalAccessTokenService.removeToken();
      } catch (_) {}

      return Right(enabled);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message:
              e.response?.data?['message']?.toString() ??
              e.message ??
              'API error',
          statusCode: e.response?.statusCode,
          code: e.response?.data?['code']?.toString(),
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearPasscode({
    required String password,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final enabled = await _remote.clearPasscode(password: password);

      if (!enabled) {
        await _journalAccessTokenService.removeToken();
      }

      return Right(enabled);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message:
              e.response?.data?['message']?.toString() ??
              e.message ??
              'API error',
          statusCode: e.response?.statusCode,
          code: e.response?.data?['code']?.toString(),
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPasscode({
    required String passcode,
  }) async {
    try {
      final connected = await _isConnected();
      if (!connected) {
        return const Left(ApiFailure(message: 'No internet connection'));
      }

      final unlock = await _remote.verifyPasscode(passcode: passcode);
      await _journalAccessTokenService.saveToken(
        token: unlock.token,
        expiresInSeconds: unlock.expiresInSeconds,
      );

      return const Right(true);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message:
              e.response?.data?['message']?.toString() ??
              e.message ??
              'API error',
          statusCode: e.response?.statusCode,
          code: e.response?.data?['code']?.toString(),
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
