// lib/features/home/presentation/home_providers.dart
import 'package:autoshop_manager/core/constants/app_constants.dart';
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
// --- ADDED: Import for Drift's 'Variable' class ---
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- EXISTING PROVIDER (UNCHANGED) ---
final upcomingServicesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final vehicleDao = ref.watch(appDatabaseProvider).vehicleDao;
  final allVehicles = await vehicleDao.getAllVehicles();

  final vehiclesWithReminders = allVehicles.where((v) {
    return v.nextReminderDate != null;
  }).toList();

  final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
  final upcoming = vehiclesWithReminders.where((v) {
    return v.nextReminderDate!.isBefore(thirtyDaysFromNow);
  }).toList();

  upcoming.sort((a, b) => a.nextReminderDate!.compareTo(b.nextReminderDate!));

  return upcoming;
});


// --- NEW DASHBOARD STATISTICS PROVIDERS ---

final activeJobsCountProvider = Provider<AsyncValue<int>>((ref) {
  final activeJobs = ref.watch(activeRepairJobsProvider);
  return activeJobs.whenData((jobs) => jobs.length);
});

final todaysRevenueProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);

  final completedJobsQuery = db.select(db.repairJobs)
    ..where((j) => j.status.equals('Completed'))
    // --- FIX: Correctly handle nullable date and use proper Drift syntax ---
    ..where((j) => j.completionDate.isNotNull())
    ..where((j) => j.completionDate.isBiggerOrEqual(Variable(startOfToday)));
  
  final jobs = await completedJobsQuery.get();
  return jobs.fold<double>(0.0, (sum, job) => sum + job.totalAmount);
});

final avgServiceTimeProvider = FutureProvider<Duration>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  final completedJobsQuery = db.select(db.repairJobs)
    ..where((j) => j.status.equals('Completed'))
    ..where((j) => j.completionDate.isNotNull());

  final jobs = await completedJobsQuery.get();
  if (jobs.isEmpty) return Duration.zero;
  
  final totalDurationInMinutes = jobs.fold<int>(0, (sum, job) {
    final duration = job.completionDate!.difference(job.creationDate);
    return sum + duration.inMinutes;
  });

  return Duration(minutes: totalDurationInMinutes ~/ jobs.length);
});

final inventoryAlertsProvider = Provider<AsyncValue<int>>((ref) {
  final inventoryItems = ref.watch(inventoryNotifierProvider);
  return inventoryItems.whenData((items) {
    return items.where((item) => item.quantity < AppConstants.lowStockThreshold).length;
  });
});


final activeTechniciansProvider = Provider<({int active, int total})>((ref) {
  return (active: 3, total: 6);
});

final vehiclesInQueueProvider = Provider<int>((ref) => 2);

final activeJobsYesterdayProvider = Provider<int>((ref) => 4);
final revenueYesterdayProvider = Provider<double>((ref) => 4830.0);
final avgServiceTimeYesterdayProvider = Provider<Duration>((ref) => const Duration(hours: 2, minutes: 45));

