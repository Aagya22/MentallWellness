import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final biometricSettingsServiceProvider = Provider<BiometricSettingsService>((
  ref,
) {
  return BiometricSettingsService(prefs: ref.read(sharedPreferencesProvider));
});

class BiometricSettingsService {
  static const String _keyBiometricLoginEnabled = 'biometric_login_enabled';

  final SharedPreferences _prefs;

  BiometricSettingsService({required SharedPreferences prefs}) : _prefs = prefs;

  bool isBiometricLoginEnabled() {
    return _prefs.getBool(_keyBiometricLoginEnabled) ?? false;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricLoginEnabled, enabled);
  }
}
