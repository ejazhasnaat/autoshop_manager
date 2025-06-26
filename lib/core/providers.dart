// lib/core/providers.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FINAL FIX: The provider now returns the singleton instance of the database,
// making it consistently available throughout the entire app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
