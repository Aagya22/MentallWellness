import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/auth/data/models/auth_api_model.dart';
import 'package:mentalwellness/features/auth/domain/entities/auth_entity.dart';

void main() {

  test('fromJson should parse JSON correctly', () {
    final json = {
      '_id': '123',
      'fullName': 'Aagya Neupane',
      'email': 'Aagya@gmail.com',
      'phoneNumber': '9800000000',
      'username': 'Aagya123',
      'password': 'secret',
      'imageUrl': 'profile.png',
      'role': 'user',
    };

    final model = AuthApiModel.fromJson(json);

    expect(model.id, '123');
    expect(model.fullName, 'Aagya Neupane');
    expect(model.email, 'Aagya@gmail.com');
    expect(model.phoneNumber, '9800000000');
    expect(model.username, 'Aagya123');
    expect(model.profilePicture, 'profile.png');
    expect(model.role, 'user');
  });

  test('fromJson should default role to user if missing', () {
    final json = {
      'id': '123',
      'fullName': 'Aastha Niraula',
      'email': 'aastha@gmail.com',
      'username': 'aastha123',
    };

    final model = AuthApiModel.fromJson(json);

    expect(model.role, 'user');
  });

  test('toEntity should map AuthApiModel to AuthEntity', () {
    final model = AuthApiModel(
      id: '123',
      fullName: 'Aagya',
      email: 'Aagya@test.com',
      phoneNumber: null,
      username: 'Aagya01',
      password: 'pass',
      profilePicture: null,
      role: null,
    );

    final entity = model.toEntity();

    expect(entity.authId, '123');
    expect(entity.fullName, 'Aagya');
    expect(entity.email, 'Aagya@test.com');
    expect(entity.phoneNumber, '');
    expect(entity.username, 'Aagya01');
    expect(entity.role, 'user');
  });
}
