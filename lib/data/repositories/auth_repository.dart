// lib/data/repositories/auth_repository.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/core/providers.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(appDatabaseProvider));
});

class AuthRepository {
  final AppDatabase _db;
  AuthRepository(this._db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- UPDATED: Method signature and logic updated for new fields ---
  Future<void> performInitialSetup({
    required String workshopName,
    required String managerName,
    required String phone,
    required String address,
    required String adminUsername,
    required String adminPassword,
    required String adminFullName,
    // Standard user details are now nullable
    String? userUsername,
    String? userPassword,
    String? userFullName,
    String? userRole,
  }) async {
    return _db.transaction(() async {
      // 1. Update Shop Settings
      final settingsCompanion = ShopSettingsCompanion(
        workshopName: drift.Value(workshopName),
        workshopManagerName: drift.Value(managerName),
        workshopPhoneNumber: drift.Value(phone),
        workshopAddress: drift.Value(address),
      );
      await (_db.update(_db.shopSettings)..where((tbl) => tbl.id.equals(1))).write(settingsCompanion);

      // 2. Create Admin User
      final adminCompanion = UsersCompanion(
        username: drift.Value(adminUsername),
        fullName: drift.Value(adminFullName),
        passwordHash: drift.Value(_hashPassword(adminPassword)),
        role: const drift.Value('Admin'),
        forcePasswordReset: const drift.Value(false),
      );
      await _db.into(_db.users).insert(adminCompanion);

      // 3. Conditionally create Standard User
      if (userUsername != null && userPassword != null && userFullName != null && userRole != null) {
        final userCompanion = UsersCompanion(
          username: drift.Value(userUsername),
          fullName: drift.Value(userFullName),
          passwordHash: drift.Value(_hashPassword(userPassword)),
          role: drift.Value(userRole),
          forcePasswordReset: const drift.Value(true),
        );
        await _db.into(_db.users).insert(userCompanion);
      }
    });
  }

  Future<User?> login(String username, String password) async {
    final passwordHash = _hashPassword(password);
    final user = await (_db.select(_db.users)
          ..where((u) => u.username.equals(username) & u.passwordHash.equals(passwordHash)))
        .getSingleOrNull();
    return user;
  }
  
  Future<bool> userExists(String username) async {
    final user = await (_db.select(_db.users)..where((u) => u.username.equals(username))).getSingleOrNull();
    return user != null;
  }

  Future<User> signup(String username, String password, String role, {String? fullName}) async {
    final passwordHash = _hashPassword(password);
    final companion = UsersCompanion(
      username: drift.Value(username),
      fullName: drift.Value(fullName),
      passwordHash: drift.Value(passwordHash),
      role: drift.Value(role),
    );
    return await _db.into(_db.users).insertReturning(companion);
  }

  Stream<List<User>> getAllUsers() {
    return _db.select(_db.users).watch();
  }

  Future<bool> deleteUser(int userId) async {
    final count = await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
    return count > 0;
  }
}
