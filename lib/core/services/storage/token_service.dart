// provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(
    prefs: ref.read(sharedPreferencesProvider),
  );
});

class TokenService {
  static const String _tokenKey = 'auth_token';
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  TokenService({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Save token
  Future<void> saveToken(String token) async {
    await Future.wait([
      _prefs.setString(_tokenKey, token),
      _secureStorage.write(key: _tokenKey, value: token),
    ]);
  }

  // Get token
  Future<String?> getToken() async {
    final inMemoryToken = _prefs.getString(_tokenKey);
    if (inMemoryToken != null && inMemoryToken.isNotEmpty) {
      return inMemoryToken;
    }
    return _secureStorage.read(key: _tokenKey);
  }

  // Remove token (for logout)
  Future<void> removeToken() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _secureStorage.delete(key: _tokenKey),
    ]);
  }
}