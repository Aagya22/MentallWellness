import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/token_service.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/auth/data/datasources/auth_datasource.dart';
import 'package:mentalwellness/features/auth/data/models/auth_api_model.dart';
import 'package:dio/dio.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;
  final TokenService _tokenService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
    required TokenService tokenService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService,
        _tokenService = tokenService;

  @override
  Future<AuthApiModel?> getUserById(String authId) async {
    final response = await _apiClient.get('${ApiEndpoints.user}/$authId');
    if (response.data["success"] == true) {
      final data = response.data["data"] as Map<String, dynamic>;
      return AuthApiModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.userLogin,
      data: {"email": email, "password": password},
    );

    print('=== LOGIN RESPONSE ===');
    print(response.data);

    if (response.data["success"] == true) {
      final data = response.data["data"] as Map<String, dynamic>;
      print('=== USER DATA ===');
      print(data);
      
      final user = AuthApiModel.fromJson(data);
      
      print('=== PARSED USER ===');
      print('User profilePicture: ${user.profilePicture}');

      final token = response.data["token"] as String?;
      if (token != null && token.isNotEmpty) {
        await _tokenService.saveToken(token);
      }

      await _userSessionService.saveUserSession(
        userId: user.id!,
        email: user.email,
        fullName: user.fullName,
        username: user.username,
        phoneNumber: user.phoneNumber,
        profilePicture: user.profilePicture,
      );

      return user;
    }

    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final response = await _apiClient.post(
      ApiEndpoints.userRegister,
      data: user.toJson(),
    );

    if (response.data["success"] == true) {
      final data = response.data["data"] as Map<String, dynamic>;
      final registeredUser = AuthApiModel.fromJson(data);

      final token = response.data["token"] as String?;
      if (token != null && token.isNotEmpty) {
        await _tokenService.saveToken(token);
      }

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
  }

  @override
  Future<String> uploadPhoto(File photo) async {
    final fileName = photo.path.split('/').last;
    final formData = FormData.fromMap({
      'itemPhoto': await MultipartFile.fromFile(photo.path, filename: fileName),
    });

    final token = await _tokenService.getToken();

    final response = await _apiClient.put(
    ApiEndpoints.userUpdateProfile, 
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );
    return response.data['data'];
  }

  @override
  Future<AuthApiModel?> updateUser(String userId, Map<String, dynamic> data, File? imageFile) async {
    final formData = FormData.fromMap(data);

    if (imageFile != null) {
      final fileName = imageFile.path.split('/').last;
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(imageFile.path, filename: fileName),
        ),
      );
    }

    final response = await _apiClient.put(
      ApiEndpoints.userUpdateProfile,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.data["success"] == true) {
      final updatedData = response.data["data"] as Map<String, dynamic>;
      final updatedUser = AuthApiModel.fromJson(updatedData);

      await _userSessionService.saveUserSession(
        userId: updatedUser.id!,
        email: updatedUser.email,
        fullName: updatedUser.fullName,
        username: updatedUser.username,
        phoneNumber: updatedUser.phoneNumber,
        profilePicture: updatedUser.profilePicture,
      );

      return updatedUser;
    }

    return null;
  }
}