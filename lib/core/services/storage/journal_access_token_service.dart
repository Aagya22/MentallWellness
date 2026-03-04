import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final journalAccessTokenServiceProvider = Provider<JournalAccessTokenService>((
  ref,
) {
  return JournalAccessTokenService(prefs: ref.read(sharedPreferencesProvider));
});

class JournalAccessTokenService {
  static const String _tokenKey = 'journal_access_token';
  static const String _expiresAtKey = 'journal_access_token_expires_at_ms';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  JournalAccessTokenService({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  }) : _prefs = prefs,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveToken({
    required String token,
    required int expiresInSeconds,
  }) async {
    final expiresAtMs =
        DateTime.now().millisecondsSinceEpoch + (expiresInSeconds * 1000);

    await Future.wait([
      _prefs.setString(_tokenKey, token),
      _prefs.setInt(_expiresAtKey, expiresAtMs),
      _secureStorage.write(key: _tokenKey, value: token),
      _secureStorage.write(key: _expiresAtKey, value: expiresAtMs.toString()),
    ]);
  }

  Future<String?> getToken() async {
    final token = _prefs.getString(_tokenKey);
    final expiresAtMs = _prefs.getInt(_expiresAtKey);

    if (token != null && token.isNotEmpty) {
      if (_isExpired(expiresAtMs)) {
        await removeToken();
        return null;
      }
      return token;
    }

    final secureToken = await _secureStorage.read(key: _tokenKey);
    final secureExpiresAtRaw = await _secureStorage.read(key: _expiresAtKey);
    final secureExpiresAtMs = secureExpiresAtRaw != null
        ? int.tryParse(secureExpiresAtRaw)
        : null;

    if (secureToken != null && secureToken.isNotEmpty) {
      if (_isExpired(secureExpiresAtMs)) {
        await removeToken();
        return null;
      }

      // Hydrate prefs for faster access next time.
      await Future.wait([
        _prefs.setString(_tokenKey, secureToken),
        if (secureExpiresAtMs != null)
          _prefs.setInt(_expiresAtKey, secureExpiresAtMs)
        else
          _prefs.remove(_expiresAtKey),
      ]);

      return secureToken;
    }

    return null;
  }

  Future<void> removeToken() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _prefs.remove(_expiresAtKey),
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _expiresAtKey),
    ]);
  }

  bool _isExpired(int? expiresAtMs) {
    if (expiresAtMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiresAtMs;
  }
}
