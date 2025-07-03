// lib/core/providers.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider returns the singleton instance of the database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// --- ADDED: Provider for the Authentication Repository ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AuthRepository(database);
});
