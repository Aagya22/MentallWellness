import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mentalwellness/core/constants/hive_table_constant.dart';
import 'package:mentalwellness/features/auth/data/models/auth_hive_model.dart';
import 'package:path_provider/path_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);
    _registerAdapter();
    await _openBoxes();
  }

  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
  }

  Box<AuthHiveModel> get _authBox =>
      Hive.box<AuthHiveModel>(HiveTableConstant.authTable);

  Future<void> register(AuthHiveModel user) async {
    await _authBox.put(user.authId, user);
  }

  AuthHiveModel? login(String email, String password) {
    try {
      return _authBox.values.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  AuthHiveModel? getUserById(String authId) {
    return _authBox.get(authId);
  }

  Future<AuthHiveModel?> getUserByEmail(String email) async {
    try {
      return _authBox.values.firstWhere((user) => user.email == email);
    } catch (_) {
      return null;
    }
  }

  bool isEmailRegistered(String email) {
    return _authBox.values.any((user) => user.email == email);
  }

  Future<bool> updateUser(AuthHiveModel newUser) async {
    final existing = _authBox.get(newUser.authId);

    if (existing == null) return false;

    final mergedUser = AuthHiveModel(
      authId: existing.authId,
      fullName: newUser.fullName,
      email: newUser.email,
      phoneNumber: newUser.phoneNumber,
      username: newUser.username,
      password: newUser.password ?? existing.password,
      profilePicture: newUser.profilePicture?.isNotEmpty == true
          ? newUser.profilePicture
          : existing.profilePicture,
      role: newUser.role,
    );

    await _authBox.put(existing.authId, mergedUser);
    return true;
  }

  Future<void> deleteUser(String authId) async {
    await _authBox.delete(authId);
  }

  Future<void> deleteProfilePicture(String authId) async {
    final existing = _authBox.get(authId);
    if (existing == null) return;

    final updated = AuthHiveModel(
      authId: existing.authId,
      fullName: existing.fullName,
      email: existing.email,
      phoneNumber: existing.phoneNumber,
      username: existing.username,
      password: existing.password,
      profilePicture: null,
      role: existing.role,
    );

    await _authBox.put(authId, updated);
  }
}