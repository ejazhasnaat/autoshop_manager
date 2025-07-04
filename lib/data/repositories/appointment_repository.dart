// lib/data/repositories/appointment_repository.dart
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(appDatabaseProvider));
});

class AppointmentRepository {
  final AppDatabase _db;
  AppointmentRepository(this._db);

  Stream<List<DateTime>> watchAllAppointmentDates() {
    return _db.appointmentDao.watchAllAppointmentDates();
  }

  Future<AppointmentWithDetails?> getAppointmentById(int id) {
     final query = _db.select(_db.appointments)..where((a) => a.id.equals(id));
     
     return query.join([
      innerJoin(_db.customers, _db.customers.id.equalsExp(_db.appointments.customerId)),
      innerJoin(_db.vehicles, _db.vehicles.id.equalsExp(_db.appointments.vehicleId)),
    ]).getSingleOrNull().then((row) {
        if (row == null) return null;
        return AppointmentWithDetails(
          appointment: row.readTable(_db.appointments),
          customer: row.readTable(_db.customers),
          vehicle: row.readTable(_db.vehicles),
        );
      });
  }
  
  Future<int> addAppointment(AppointmentsCompanion entry) {
    return _db.into(_db.appointments).insert(entry);
  }

  Future<bool> updateAppointment(int id, AppointmentsCompanion entry) {
    return (_db.update(_db.appointments)..where((a) => a.id.equals(id))).write(entry).then((count) => count > 0);
  }

  Future<int> deleteAppointment(int id) {
    return (_db.delete(_db.appointments)..where((a) => a.id.equals(id))).go();
  }
}
