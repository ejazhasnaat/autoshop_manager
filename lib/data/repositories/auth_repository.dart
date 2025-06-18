// lib/data/repositories/auth_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/core/constants/app_constants.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // <--- IMPORT AppDatabase here
import 'package:autoshop_manager/data/repositories/vehicle_model_repository.dart'; // <--- NEW: Import VehicleModelRepository for seeding
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart'; // <--- NEW: Import AuthUser from here

// CENTRALIZED APP DATABASE PROVIDER: Define it once here for all repositories to use
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(appDatabaseProvider),
    ref.read(vehicleModelRepositoryProvider), // Inject VehicleModelRepository for seeding
  );
});

class AuthRepository {
  final AppDatabase _db;
  final VehicleModelRepository _vehicleModelRepo; // For seeding

  AuthRepository(this._db, this._vehicleModelRepo);

  Future<AuthUser?> login(String username, String password) async {
    final hashedPassword = _hashPassword(password);
    final user = await (_db.select(_db.users)
          ..where((u) => u.username.equals(username) & u.passwordHash.equals(hashedPassword)))
        .getSingleOrNull();

    if (user != null) {
      return AuthUser(id: user.id!, username: user.username, role: user.role);
    }
    return null;
  }

  Future<void> initializeAdminUser() async {
    final adminExists = await (_db.select(_db.users)..where((u) => u.username.equals(AppConstants.defaultAdminUsername))).getSingleOrNull();

    if (adminExists == null) {
      await _db.into(_db.users).insert(UsersCompanion.insert(
            username: AppConstants.defaultAdminUsername,
            passwordHash: _hashPassword(AppConstants.defaultAdminPin),
            role: const Value('Admin'),
          ));
    }
    // Seed default vehicle models after users are set up
    await _vehicleModelRepo.seedDefaultVehicleModels('assets/vehicle_models.json');
  }

  Future<AuthUser?> signup(String username, String password, String role) async {
    final hashedPassword = _hashPassword(password);
    try {
      final userId = await _db.into(_db.users).insert(UsersCompanion.insert(
            username: username,
            passwordHash: hashedPassword,
            role: Value(role),
          ));
      if (userId > 0) {
        return AuthUser(id: userId, username: username, role: role);
      }
      return null;
    } catch (e) {
      print('Error during signup: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    return _db.select(_db.users).get();
  }

  Future<bool> deleteUser(int userId) async {
    final count = await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
    return count > 0;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

