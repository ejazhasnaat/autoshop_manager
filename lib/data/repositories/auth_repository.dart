// lib/data/repositories/auth_repository.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:drift/drift.dart';

class AuthRepository {
  final AppDatabase _db;

  AuthRepository(this._db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> login(String username, String password) async {
    final user = await (_db.select(_db.users)..where((u) => u.username.equals(username))).getSingleOrNull();
    if (user != null && user.passwordHash == _hashPassword(password)) {
      return user;
    }
    return null;
  }

  Future<bool> userExists(String username) async {
    final user = await (_db.select(_db.users)..where((u) => u.username.equals(username))).getSingleOrNull();
    return user != null;
  }

  Future<User> signup(String username, String password, String role, {String? fullName}) async {
    final newUserCompanion = UsersCompanion(
      username: Value(username),
      passwordHash: Value(_hashPassword(password)),
      role: Value(role),
      fullName: Value(fullName),
    );
    final id = await _db.into(_db.users).insert(newUserCompanion);
    return User(id: id, username: username, passwordHash: newUserCompanion.passwordHash.value, role: role, fullName: fullName, forcePasswordReset: false);
  }

  Stream<List<User>> getAllUsers() {
    return _db.select(_db.users).watch();
  }
  
  Future<bool> deleteUser(int userId) async {
    final count = await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
    return count > 0;
  }
  
  // --- FIX: Updated logic to correctly handle saves with no data changes ---
  Future<void> updateUser({
    required int userId,
    required String fullName,
    String? newPassword,
  }) async {
    final companion = UsersCompanion(
      fullName: Value(fullName),
      passwordHash: newPassword != null && newPassword.isNotEmpty
          ? Value(_hashPassword(newPassword))
          : const Value.absent(),
    );

    // This performs a partial update. If no error is thrown, it's considered a success.
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(companion);
  }

  Future<void> performInitialSetup({
    required String workshopName,
    required String managerName,
    required String phone,
    required String address,
    required String adminUsername,
    required String adminPassword,
    required String adminFullName,
    String? userUsername,
    String? userPassword,
    String? userFullName,
    String? userRole,
  }) async {
    await _db.transaction(() async {
      final settingsCompanion = ShopSettingsCompanion(
        workshopName: Value(workshopName),
        workshopManagerName: Value(managerName),
        workshopPhoneNumber: Value(phone),
        workshopAddress: Value(address),
      );
      await (_db.update(_db.shopSettings)..where((tbl) => tbl.id.equals(1))).write(settingsCompanion);

      await signup(adminUsername, adminPassword, 'Admin', fullName: adminFullName);

      if (userUsername != null && userPassword != null && userRole != null) {
        await signup(userUsername, userPassword, userRole, fullName: userFullName);
      }
    });
  }
}

