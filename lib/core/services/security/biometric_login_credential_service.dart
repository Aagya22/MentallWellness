import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final biometricLoginCredentialServiceProvider =
    Provider<BiometricLoginCredentialService>((ref) {
  return BiometricLoginCredentialService();
});

class BiometricLoginCredentials {
  final String email;
  final String password;

  const BiometricLoginCredentials({required this.email, required this.password});
}

class BiometricLoginCredentialService {
  static const String _emailKey = 'biometric_login_email';
  static const String _passwordKey = 'biometric_login_password';

  final FlutterSecureStorage _secureStorage;

  BiometricLoginCredentialService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _emailKey, value: email),
      _secureStorage.write(key: _passwordKey, value: password),
    ]);
  }

  Future<BiometricLoginCredentials?> getCredentials() async {
    final values = await Future.wait([
      _secureStorage.read(key: _emailKey),
      _secureStorage.read(key: _passwordKey),
    ]);

    final email = values[0]?.trim();
    final password = values[1];

    if (email == null || email.isEmpty) return null;
    if (password == null || password.isEmpty) return null;

    return BiometricLoginCredentials(email: email, password: password);
  }

  Future<void> clearCredentials() async {
    await Future.wait([
      _secureStorage.delete(key: _emailKey),
      _secureStorage.delete(key: _passwordKey),
    ]);
  }
}
