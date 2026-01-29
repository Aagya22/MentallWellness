import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserSessionService(prefs: prefs);
});

class UserSessionService {
  final SharedPreferences _prefs;

  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserFullName = 'user_full_name';
  static const _keyUserUsername = 'user_username';
  static const _keyUserPhoneNumber = 'user_phone_number';
  static const _keyUserRole = 'user_role';
  static const _keyUserProfilePicture = 'user_profile_picture';
  static const _keyOnboardingCompleted = 'onboarding_completed';

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String fullName,
    required String username,
    String? phoneNumber,
    String? role,
    String? profilePicture,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setBool(_keyOnboardingCompleted, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserFullName, fullName);
    await _prefs.setString(_keyUserUsername, username);

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _prefs.setString(_keyUserPhoneNumber, phoneNumber);
    } else {
      await _prefs.remove(_keyUserPhoneNumber);
    }

    if (role != null && role.isNotEmpty) {
      await _prefs.setString(_keyUserRole, role);
    }

    if (profilePicture != null && profilePicture.isNotEmpty) {
      await _prefs.setString(_keyUserProfilePicture, profilePicture);
    } else {
      await _prefs.remove(_keyUserProfilePicture);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String username,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    await _prefs.setString(_keyUserFullName, fullName);
    await _prefs.setString(_keyUserUsername, username);

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _prefs.setString(_keyUserPhoneNumber, phoneNumber);
    }

    if (profilePicture != null && profilePicture.isNotEmpty) {
      await _prefs.setString(_keyUserProfilePicture, profilePicture);
    }
  }

  bool isLoggedIn() => _prefs.getBool(_keyIsLoggedIn) ?? false;

  String? getCurrentUserId() => _prefs.getString(_keyUserId);
  String? getCurrentUserEmail() => _prefs.getString(_keyUserEmail);
  String? getCurrentUserFullName() => _prefs.getString(_keyUserFullName);
  String? getCurrentUserUsername() => _prefs.getString(_keyUserUsername);
  String? getCurrentUserPhoneNumber() => _prefs.getString(_keyUserPhoneNumber);
  String? getCurrentUserRole() => _prefs.getString(_keyUserRole);
  String? getCurrentUserProfilePicture() => _prefs.getString(_keyUserProfilePicture);

  bool isOnboardingCompleted() =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> clearSession() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyUserUsername);
    await _prefs.remove(_keyUserPhoneNumber);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyUserProfilePicture);
  }

  Future<void> deleteProfilePicture() async {
    await _prefs.remove(_keyUserProfilePicture);
  }
}