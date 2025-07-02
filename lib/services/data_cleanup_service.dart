// lib/services/data_cleanup_service.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/core/providers.dart';

final dataCleanupServiceProvider = Provider<DataCleanupService>((ref) {
  return DataCleanupService(
    ref.read(appDatabaseProvider),
    ref.read(preferenceRepositoryProvider)
  );
});

class DataCleanupService {
  final AppDatabase _db;
  final PreferenceRepository _prefsRepo;

  DataCleanupService(this._db, this._prefsRepo);

  Future<int> deleteOldCompletedJobs() async {
    try {
      final prefs = await _prefsRepo.getPreferences();
      final retentionPeriod = prefs.historyRetentionPeriod;
      final retentionUnit = prefs.historyRetentionUnit;

      final now = DateTime.now();
      DateTime cutoffDate;

      switch (retentionUnit) {
        case 'Days':
          cutoffDate = now.subtract(Duration(days: retentionPeriod));
          break;
        case 'Months':
          cutoffDate = DateTime(now.year, now.month - retentionPeriod, now.day);
          break;
        case 'Years':
        default:
          cutoffDate = DateTime(now.year - retentionPeriod, now.month, now.day);
          break;
      }

      final count = await _db.transaction(() async {
        final query = _db.delete(_db.repairJobs)
          ..where((job) => job.status.equals('Completed'))
          // --- FIX: Add a check to ensure completionDate is not null before comparing ---
          ..where((job) => job.completionDate.isNotNull())
          // --- FIX: Use the correct Drift syntax for date comparison with a non-nullable column ---
          ..where((job) => job.completionDate.isSmallerThan(Variable(cutoffDate)));

        return await query.go();
      });

      print('Successfully deleted $count old completed repair jobs.');
      return count;

    } catch (e) {
      print('Error during data cleanup: $e');
      return 0;
    }
  }
}

