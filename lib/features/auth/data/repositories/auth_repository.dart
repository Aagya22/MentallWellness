import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/connectivity/network_info.dart';
import 'package:mentalwellness/core/services/storage/token_service.dart';
import '../../../../core/error/failures.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_api_model.dart';
import '../models/auth_hive_model.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Create provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authLocalDatasource = ref.read(authLocalDataSourceProvider);
  final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  final tokenService = ref.read(tokenServiceProvider);
  return AuthRepository(
    authLocalDatasource: authLocalDatasource,
    authRemoteDatasource: authRemoteDatasource,
    networkInfo: networkInfo,
    tokenService: tokenService,
  );
});

class AuthRepository implements IAuthRepository {
  final AuthLocalDataSource _authLocalDataSource;
  final AuthRemoteDatasource _authRemoteDatasource;
  final INetworkInfo _networkInfo;
  final TokenService _tokenService;

  AuthRepository({
    required AuthLocalDataSource authLocalDatasource,
    required AuthRemoteDatasource authRemoteDatasource,
    required INetworkInfo networkInfo,
    required TokenService tokenService,
  }) : _authLocalDataSource = authLocalDatasource,
       _authRemoteDatasource = authRemoteDatasource,
       _networkInfo = networkInfo,
       _tokenService = tokenService;
  // Simple helper to check connectivity
  Future<bool> _isConnected() => _networkInfo.isConnected;

  @override
  Future<Either<Failure, bool>> register(AuthEntity user) async {
    try {
      final connected = await _isConnected();

      // If offline, save locally only
      if (!connected) {
        final existing = await _authLocalDataSource.getUserByEmail(user.email);
        if (existing != null) {
          return const Left(
            LocalDatabaseFailure(message: 'This email is already registered'),
          );
        }
        await _authLocalDataSource.register(AuthHiveModel.fromEntity(user));
        return const Right(true);
      }

      // Online: try remote, then cache locally
      try {
        await _authRemoteDatasource.register(AuthApiModel.fromEntity(user));
        await _authLocalDataSource.register(AuthHiveModel.fromEntity(user));
        return const Right(true);
      } catch (e) {
        // Remote failed: fallback to local register
        final existing = await _authLocalDataSource.getUserByEmail(user.email);
        if (existing != null) {
          return const Left(
            LocalDatabaseFailure(message: 'This email is already registered'),
          );
        }
        await _authLocalDataSource.register(AuthHiveModel.fromEntity(user));
        return const Right(true);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final connected = await _isConnected();

      if (connected) {
        // Try remote login first
        try {
          final apiUser = await _authRemoteDatasource.login(email, password);
          if (apiUser != null) {
            // cache via local datasource (it will save session)
            await _authLocalDataSource.login(email, password);
            return Right(apiUser.toEntity());
          }
          return const Left(
            LocalDatabaseFailure(
              message: 'Invalid credentials. Please try again.',
            ),
          );
        } catch (_) {
          // Remote failed -> try local
          final localUser = await _authLocalDataSource.login(email, password);
          if (localUser != null) return Right(localUser.toEntity());
          return const Left(
            LocalDatabaseFailure(
              message: 'Invalid credentials. Please try again.',
            ),
          );
        }
      } else {
        // Offline: local login only
        final localUser = await _authLocalDataSource.login(email, password);
        if (localUser != null) return Right(localUser.toEntity());
        return const Left(
          LocalDatabaseFailure(
            message: 'Invalid credentials. Please try again.',
          ),
        );
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      // Prefer local session data; if online try to refresh from API
      final local = await _authLocalDataSource.getCurrentUser();
      final connected = await _isConnected();

      if (connected && local != null && local.authId != null) {
        try {
          final apiUser = await _authRemoteDatasource.getUserById(
            local.authId!,
          );
          if (apiUser != null) return Right(apiUser.toEntity());
        } catch (_) {
          // ignore and fall back to local
        }
      }

      if (local != null) return Right(local.toEntity());
      return const Left(LocalDatabaseFailure(message: 'Session expired'));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      // Always clear local session
      final localResult = await _authLocalDataSource.logout();
      await _tokenService.removeToken();
      // Optionally notify server if online (not implemented)
      return Right(localResult);
    } catch (e) {
      return Left(
        LocalDatabaseFailure(message: 'Logout failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getUserByEmail(String email) async {
    try {
      // Simple approach: check local first, do not call remote by email
      final local = await _authLocalDataSource.getUserByEmail(email);
      if (local != null) return Right(local.toEntity());
      return const Left(
        LocalDatabaseFailure(message: 'No user found with this email'),
      );
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
