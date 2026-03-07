import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final journalPasscodeCacheServiceProvider = Provider<JournalPasscodeCacheService>(
  (ref) {
    return JournalPasscodeCacheService();
  },
);

class JournalPasscodeCacheService {
  static const String _key = 'cached_journal_passcode';

  final FlutterSecureStorage _secureStorage;

  JournalPasscodeCacheService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> savePasscode(String passcode) async {
    await _secureStorage.write(key: _key, value: passcode);
  }

  Future<String?> getPasscode() async {
    final v = await _secureStorage.read(key: _key);
    if (v == null) return null;
    final cleaned = v.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> clearPasscode() async {
    await _secureStorage.delete(key: _key);
  }
}
