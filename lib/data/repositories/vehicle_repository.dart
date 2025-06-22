// lib/data/repositories/vehicle_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'
    hide Column; // Import Value for inserts/updates
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/core/providers.dart';

// Riverpod Provider for VehicleRepository
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.read(appDatabaseProvider));
});

class VehicleRepository {
  final AppDatabase _db;

  VehicleRepository(this._db);

  /// Retrieves all vehicles for a specific customer.
  Future<List<Vehicle>> getVehiclesByCustomerId(int customerId) async {
    return (_db.select(
      _db.vehicles,
    )..where((v) => v.customerId.equals(customerId))).get();
  }

  /// Retrieves a single vehicle by its ID.
  Future<Vehicle?> getVehicleById(int id) async {
    return (_db.select(
      _db.vehicles,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Adds a new vehicle to the database.
  Future<int> addVehicle(VehiclesCompanion entry) async {
    return _db.into(_db.vehicles).insert(entry);
  }

  /// Updates an existing vehicle in the database.
  Future<bool> updateVehicle(Vehicle vehicle) async {
    return _db.update(_db.vehicles).replace(vehicle);
  }

  /// Deletes a vehicle by its ID.
  Future<bool> deleteVehicle(int id) async {
    final count = await (_db.delete(
      _db.vehicles,
    )..where((v) => v.id.equals(id))).go();
    return count > 0;
  }

  /// Deletes all vehicles associated with a given customer ID.
  Future<int> deleteVehiclesByCustomerId(int customerId) async {
    return await (_db.delete(
      _db.vehicles,
    )..where((v) => v.customerId.equals(customerId))).go();
  }
}
