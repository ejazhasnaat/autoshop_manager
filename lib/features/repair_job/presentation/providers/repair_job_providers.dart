// lib/features/repair_job/presentation/providers/repair_job_providers.dart
// --- FINAL FIX: Using the correct import path for your project ---
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repair_job_providers.g.dart';

@riverpod
RepairJobDao repairJobDao(RepairJobDaoRef ref) {
  // This will now resolve correctly
  return ref.watch(appDatabaseProvider).repairJobDao;
}

@riverpod
Stream<List<RepairJobWithCustomer>> activeRepairJobs(ActiveRepairJobsRef ref) {
  final dao = ref.watch(repairJobDaoProvider);
  return dao.watchActiveJobs();
}

@riverpod
Stream<int> activeRepairJobCount(ActiveRepairJobCountRef ref) {
  return ref.watch(activeRepairJobsProvider.stream).map((jobs) => jobs.length);
}

@riverpod
Stream<RepairJobWithDetails> repairJobDetails(
    RepairJobDetailsRef ref, int jobId) {
  final dao = ref.watch(repairJobDaoProvider);
  return dao.watchJobDetails(jobId);
}
