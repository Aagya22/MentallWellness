import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(localAuth: LocalAuthentication());
});

class BiometricAuthService {
  final LocalAuthentication _localAuth;

  String? _lastErrorCode;
  String? _lastErrorMessage;

  BiometricAuthService({required LocalAuthentication localAuth})
    : _localAuth = localAuth;

  String? get lastErrorCode => _lastErrorCode;
  String? get lastErrorMessage => _lastErrorMessage;

  String? get userFriendlyError {
    final raw = _lastErrorCode;
    if (raw == null || raw.trim().isEmpty) return null;

    final code = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-\s]'), '');

    switch (code) {
      case 'notenrolled':
        return 'No biometrics are set up on this device. Add a fingerprint/Face ID/Windows Hello in your device settings, then try again.';
      case 'passcodenotset':
        return 'Set up a device screen lock (PIN/Passcode) first, then enable biometrics.';
      case 'notavailable':
        return 'Biometrics are not available on this device.';
      case 'lockedout':
      case 'permanentlylockedout':
        return 'Biometrics are temporarily locked. Use your device passcode and try again.';
      default:
        return null;
    }
  }

  Future<bool> isBiometricSupported() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb) return false;

    _lastErrorCode = null;
    _lastErrorMessage = null;

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      _lastErrorCode = e.code;
      _lastErrorMessage = e.message;
      return false;
    } catch (e) {
      _lastErrorMessage = e.toString();
      return false;
    }
  }
}
