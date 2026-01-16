import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_datasource.dart';
import 'package:mentalwellness/features/auth/data/models/auth_api_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return AuthRemoteDatasource(
    apiClient: apiClient,
    userSessionService: userSessionService,
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;
  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  }) : _apiClient = apiClient,
       _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> getUserById(String authId) async {
    final response = await _apiClient.get('${ApiEndpoints.user}/$authId');
    if (response.data["success"] == true) {
      final data = response.data["data"] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);
      return user;
    } else {
      return null;
    }
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.userLogin,
        data: {"email": email, "password": password},
      );
      if (response.data["success"] == true) {
        final data = response.data["data"] as Map<String, dynamic>;
        final user = AuthApiModel.fromJson(data);
        // Save user session to SharedPreferences 
        await _userSessionService.saveUserSession(
          userId: user.id!,
          email: user.email,
          fullName: user.fullName,
          username: user.username,
          phoneNumber: user.phoneNumber,
          profilePicture: user.profilePicture,
        );
        return user;
      } else {
        return null;
      }
    } catch (e) {
      // Re-throw to allow repository to handle and fallback to Hive
      rethrow;
    }
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.userRegister,
        data: user.toJson(),
      );
      if (response.data["success"] == true) {
        final data = response.data["data"] as Map<String, dynamic>;
        final registeredUser = AuthApiModel.fromJson(data);
        // Save user session to SharedPreferences
        await _userSessionService.saveUserSession(
          userId: registeredUser.id!,
          email: registeredUser.email,
          fullName: registeredUser.fullName,
          username: registeredUser.username,
          phoneNumber: registeredUser.phoneNumber,
          profilePicture: registeredUser.profilePicture,
        );
        return registeredUser;
      }
      return user;
    } catch (e) {
      // Re-throw to allow repository to handle and fallback to Hive
      rethrow;
    }
  }
}