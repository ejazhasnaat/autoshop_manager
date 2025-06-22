// lib/core/providers.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the single instance of the AppDatabase.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
// Provides the VehicleModelNotifier, which manages the state of vehicle models.
