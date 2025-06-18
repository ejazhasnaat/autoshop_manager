// lib/data/repositories/service_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'
    hide Column; // Import Value for inserts/updates
import 'package:autoshop_manager/data/database/app_database.dart'; // For AppDatabase and Service types
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // For appDatabaseProvider

// Riverpod Provider for ServiceRepository
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.read(appDatabaseProvider));
});

class ServiceRepository {
  final AppDatabase _db;

  ServiceRepository(this._db);

  /// Retrieves all services from the database.
  Future<List<Service>> getAllServices() async {
    return _db.select(_db.services).get();
  }

  /// Retrieves a single service by its ID.
  Future<Service?> getServiceById(int id) async {
    return (_db.select(
      _db.services,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Adds a new service to the database.
  Future<int> addService(ServicesCompanion entry) async {
    return _db.into(_db.services).insert(entry);
  }

  /// Updates an existing service in the database.
  Future<bool> updateService(Service service) async {
    // replace will update the row identified by the primary key (id)
    return _db.update(_db.services).replace(service);
  }

  /// Deletes a service by its ID.
  Future<bool> deleteService(int id) async {
    final count = await (_db.delete(
      _db.services,
    )..where((s) => s.id.equals(id))).go();
    return count > 0;
  }
}
