// lib/features/home/presentation/home_providers.dart
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider fetches all vehicles and filters them to find those
// with a reminder date set within the next 30 days.
final upcomingServicesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final vehicleDao = ref.watch(appDatabaseProvider).vehicleDao;
  final allVehicles = await vehicleDao.getAllVehicles();

  // Filter vehicles that have a reminder date set
  final vehiclesWithReminders = allVehicles.where((v) {
    return v.nextReminderDate != null;
  }).toList();

  // Filter for reminders due in the next 30 days
  final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
  final upcoming = vehiclesWithReminders.where((v) {
    return v.nextReminderDate!.isBefore(thirtyDaysFromNow);
  }).toList();

  // Sort the list so the most urgent reminders are first
  upcoming.sort((a, b) => a.nextReminderDate!.compareTo(b.nextReminderDate!));

  return upcoming;
});
