// lib/features/schedule/presentation/schedule_providers.dart
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/appointment_repository.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/data/repositories/service_repository.dart';
import 'package:autoshop_manager/data/repositories/vehicle_repository.dart';
import 'package:autoshop_manager/features/schedule/presentation/notifiers/add_edit_appointment_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appointmentDatesProvider = StreamProvider.autoDispose<List<DateTime>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchAllAppointmentDates();
});

final addEditAppointmentNotifierProvider =
    StateNotifierProvider.autoDispose<AddEditAppointmentNotifier, AddEditAppointmentState>((ref) {
  return AddEditAppointmentNotifier(
    ref.watch(customerRepositoryProvider),
    ref.watch(vehicleRepositoryProvider),
    ref.watch(appointmentRepositoryProvider),
    ref.watch(serviceRepositoryProvider),
  );
});

// Manages the currently selected date in the calendar
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Manages the focused date in the calendar (for UI interaction)
final focusedDateProvider = StateProvider<DateTime>((ref) {
  return ref.watch(selectedDateProvider);
});

// Provides a stream of appointments for the currently selected date
final appointmentsForDateProvider = StreamProvider.autoDispose<List<AppointmentWithDetails>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return db.appointmentDao.watchAppointmentsForDate(selectedDate);
});

// Computes statistics for the selected day's appointments
final appointmentStatsProvider = Provider.autoDispose<AppointmentStats>((ref) {
  final appointmentsAsync = ref.watch(appointmentsForDateProvider);
  return appointmentsAsync.when(
    data: (appointments) {
      final total = appointments.length;
      final confirmed = appointments.where((a) => a.appointment.status == 'confirmed').length;
      final pending = appointments.where((a) => a.appointment.status == 'pending').length;
      return AppointmentStats(total: total, confirmed: confirmed, pending: pending);
    },
    loading: () => AppointmentStats.zero(),
    error: (e, s) => AppointmentStats.zero(),
  );
});

class AppointmentStats {
  final int total;
  final int confirmed;
  final int pending;

  AppointmentStats({required this.total, required this.confirmed, required this.pending});

  factory AppointmentStats.zero() {
    return AppointmentStats(total: 0, confirmed: 0, pending: 0);
  }
}
