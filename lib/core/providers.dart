// lib/core/providers.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the single instance of the AppDatabase.
// It now throws an error by default to enforce that it must be overridden
// in the ProviderScope at the root of the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in main.dart',
  );
});
