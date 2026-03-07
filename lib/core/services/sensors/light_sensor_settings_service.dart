import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final lightSensorSettingsServiceProvider = Provider<LightSensorSettingsService>(
  (ref) {
    return LightSensorSettingsService(
      prefs: ref.read(sharedPreferencesProvider),
    );
  },
);

class LightSensorSettingsService {
  static const String _keyLightSensorEnabled = 'light_sensor_enabled';

  final SharedPreferences _prefs;

  LightSensorSettingsService({required SharedPreferences prefs})
    : _prefs = prefs;

  bool isLightSensorEnabled() {
    return _prefs.getBool(_keyLightSensorEnabled) ?? true;
  }

  Future<void> setLightSensorEnabled(bool enabled) async {
    await _prefs.setBool(_keyLightSensorEnabled, enabled);
  }
}
