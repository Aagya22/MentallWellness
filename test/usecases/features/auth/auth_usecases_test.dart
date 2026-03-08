import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/auth/domain/entities/auth_entity.dart';
import 'package:mentalwellness/features/auth/domain/repositories/auth_repository.dart';
import 'package:mentalwellness/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mentalwellness/features/auth/domain/usecases/getuser_byemail.dart';
import 'package:mentalwellness/features/auth/domain/usecases/login_usecase.dart';
import 'package:mentalwellness/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mentalwellness/features/auth/domain/usecases/register_usecase.dart';

class _FakeAuthRepository implements IAuthRepository {
  Either<Failure, bool>? registerResponse;
  Either<Failure, AuthEntity>? loginResponse;
  Either<Failure, AuthEntity>? getUserByEmailResponse;
  Either<Failure, bool>? logoutResponse;
  Either<Failure, AuthEntity>? getCurrentUserResponse;

  int registerCalls = 0;
  int loginCalls = 0;
  int getUserByEmailCalls = 0;
  int logoutCalls = 0;
  int getCurrentUserCalls = 0;

  AuthEntity? capturedRegisterUser;
  String? capturedLoginEmail;
  String? capturedLoginPassword;
  String? capturedLookupEmail;

  @override
  Future<Either<Failure, bool>> register(AuthEntity user) async {
    registerCalls++;
    capturedRegisterUser = user;
    return registerResponse ?? const Left(ApiFailure(message: 'register not set'));
  }

  @override
  Future<Either<Failure, AuthEntity>> login(String email, String password) async {
    loginCalls++;
    capturedLoginEmail = email;
    capturedLoginPassword = password;
    return loginResponse ?? const Left(ApiFailure(message: 'login not set'));
  }

  @override
  Future<Either<Failure, AuthEntity>> getUserByEmail(String email) async {
    getUserByEmailCalls++;
    capturedLookupEmail = email;
    return getUserByEmailResponse ??
        const Left(ApiFailure(message: 'getUserByEmail not set'));
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    logoutCalls++;
    return logoutResponse ?? const Left(ApiFailure(message: 'logout not set'));
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    getCurrentUserCalls++;
    return getCurrentUserResponse ??
        const Left(ApiFailure(message: 'getCurrentUser not set'));
  }
}

void main() {
  late _FakeAuthRepository repository;

  late RegisterUseCase registerUseCase;
  late LoginUseCase loginUseCase;
  late GetUserByEmailUsecase getUserByEmailUsecase;
  late LogoutUsecase logoutUsecase;
  late GetCurrentUserUseCase getCurrentUserUseCase;

  setUp(() {
    repository = _FakeAuthRepository();
    registerUseCase = RegisterUseCase(authRepository: repository);
    loginUseCase = LoginUseCase(authRepository: repository);
    getUserByEmailUsecase = GetUserByEmailUsecase(repository);
    logoutUsecase = LogoutUsecase(authRepository: repository);
    getCurrentUserUseCase = GetCurrentUserUseCase(authRepository: repository);
  });

  test('RegisterUseCase maps RegisterParams to AuthEntity (phone omitted)', () async {
    repository.registerResponse = const Right(true);

    const params = RegisterParams(
      fullName: 'Alice Smith',
      email: 'alice@example.com',
      username: 'alice',
      password: 'password123',
      confirmPassword: 'password123',
    );

    final result = await registerUseCase(params);

    expect(result, const Right(true));
    expect(repository.registerCalls, 1);
    expect(
      repository.capturedRegisterUser,
      const AuthEntity(
        fullName: 'Alice Smith',
        email: 'alice@example.com',
        username: 'alice',
        password: 'password123',
        phoneNumber: '',
        role: 'user',
      ),
    );
  });

  test('RegisterUseCase uses provided phone number', () async {
    repository.registerResponse = const Right(true);

    const params = RegisterParams(
      fullName: 'Bob Jones',
      email: 'bob@example.com',
      username: 'bobby',
      password: 'secret',
      confirmPassword: 'secret',
      phoneNumber: '9800000000',
    );

    final result = await registerUseCase(params);

    expect(result, const Right(true));
    expect(repository.registerCalls, 1);
    expect(repository.capturedRegisterUser?.phoneNumber, '9800000000');
  });

  test('LoginUseCase forwards email and password to repository', () async {
    final user = AuthEntity(
      authId: 'u1',
      fullName: 'Alice Smith',
      email: 'alice@example.com',
      phoneNumber: '9800000000',
      username: 'alice',
      role: 'user',
    );
    repository.loginResponse = Right(user);

    final result = await loginUseCase(
      const LoginParams(email: 'alice@example.com', password: 'pw'),
    );

    expect(result, Right(user));
    expect(repository.loginCalls, 1);
    expect(repository.capturedLoginEmail, 'alice@example.com');
    expect(repository.capturedLoginPassword, 'pw');
  });

  test('GetUserByEmailUsecase forwards email and returns repository result', () async {
    final user = AuthEntity(
      authId: 'u2',
      fullName: 'Charlie',
      email: 'charlie@example.com',
      phoneNumber: '000',
      username: 'charlie',
      role: 'user',
    );
    repository.getUserByEmailResponse = Right(user);

    final result = await getUserByEmailUsecase('charlie@example.com');

    expect(result, Right(user));
    expect(repository.getUserByEmailCalls, 1);
    expect(repository.capturedLookupEmail, 'charlie@example.com');
  });

  test('LogoutUsecase calls repository.logout and returns result', () async {
    repository.logoutResponse = const Right(true);

    final result = await logoutUsecase();

    expect(result, const Right(true));
    expect(repository.logoutCalls, 1);
  });

  test('GetCurrentUserUseCase returns repository current user', () async {
    final user = AuthEntity(
      authId: 'u3',
      fullName: 'Dana',
      email: 'dana@example.com',
      phoneNumber: '111',
      username: 'dana',
      role: 'user',
    );
    repository.getCurrentUserResponse = Right(user);

    final result = await getCurrentUserUseCase();

    expect(result, Right(user));
    expect(repository.getCurrentUserCalls, 1);
  });
}
