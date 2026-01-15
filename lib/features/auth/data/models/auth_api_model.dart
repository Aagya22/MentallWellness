import 'package:mentalwellness/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String username;
  final String? password;
  final String? profilePicture;

  AuthApiModel({
    this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.username,
    this.password,
    this.profilePicture,
  });

  // fromJson
  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['_id'] as String?,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      username: json['username'] as String,
      password: json['password'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'profilePicture': profilePicture,
    };
  }

  // fromEntity
  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      id: entity.authId,
      fullName: entity.fullName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      username: entity.username,
      password: entity.password,
      profilePicture: entity.profilePicture,
    );
  }

  // toEntity
  AuthEntity toEntity() {
    return AuthEntity(
      authId: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      username: username,
      password: password,
      profilePicture: profilePicture,
    );
  }

  // toEntityList
  static List<AuthEntity> toEntityList(List<AuthApiModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
