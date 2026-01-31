import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/auth/domain/entities/auth_entity.dart';

void main() {

  test('AuthEntity supports value equality', () {
    const entity1 = AuthEntity(
      authId: '1',
      fullName: 'Ram Bahadur',
      email: 'ram@test.com',
      phoneNumber: '9800000000',
      username: 'ram123',
      password: 'secret',
      profilePicture: 'ram.png',
      role: 'user',
    );

    const entity2 = AuthEntity(
      authId: '1',
      fullName: 'Ram Bahadur',
      email: 'ram@test.com',
      phoneNumber: '9800000000',
      username: 'ram123',
      password: 'secret',
      profilePicture: 'ram.png',
      role: 'user',
    );

    expect(entity1, equals(entity2));
  });

  test('AuthEntity inequality when properties differ', () {
    const entity1 = AuthEntity(
      authId: '1',
      fullName: 'Ram',
      email: 'ram@test.com',
      phoneNumber: '9800000000',
      username: 'ram123',
    );

    const entity2 = AuthEntity(
      authId: '2',
      fullName: 'Shyam',
      email: 'shyam@test.com',
      phoneNumber: '9811111111',
      username: 'shyam123',
    );

    expect(entity1 == entity2, false);
  });

  test('AuthEntity default role should be user', () {
    const entity = AuthEntity(
      fullName: 'Gita',
      email: 'gita@test.com',
      phoneNumber: '9822222222',
      username: 'gita01',
    );

    expect(entity.role, 'user');
  });

  test('AuthEntity allows null optional fields', () {
    const entity = AuthEntity(
      authId: null,
      fullName: 'Hari',
      email: 'hari@test.com',
      phoneNumber: '',
      username: 'hari01',
      password: null,
      profilePicture: null,
    );

    expect(entity.authId, null);
    expect(entity.password, null);
    expect(entity.profilePicture, null);
  });


}
