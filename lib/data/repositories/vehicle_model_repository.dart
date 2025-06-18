// lib/data/repositories/vehicle_model_repository.dart
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart';


// Riverpod Provider for VehicleModelRepository
final vehicleModelRepositoryProvider = Provider<VehicleModelRepository>((ref) {
  return VehicleModelRepository(ref.read(appDatabaseProvider));
});

class VehicleModelRepository {
  final AppDatabase _db;

  VehicleModelRepository(this._db);

  /// Retrieves all vehicle models from the database, ordered by make and model.
  Future<List<VehicleModel>> getAllVehicleModels() async {
    return (_db.select(_db.vehicleModels)
          ..orderBy([
            (vm) => OrderingTerm(expression: vm.make),
            (vm) => OrderingTerm(expression: vm.model), // Order by model
          ]))
        .get();
  }

  /// Retrieves a single vehicle model by its composite primary key (make and model).
  Future<VehicleModel?> getVehicleModelByMakeModel(String make, String model) async {
    return (_db.select(_db.vehicleModels)
          ..where((vm) => vm.make.equals(make) & vm.model.equals(model)))
        .getSingleOrNull();
  }

  /// Adds a new vehicle model to the database.
  Future<bool> addVehicleModel(VehicleModelsCompanion entry) async {
    try {
      await _db.into(_db.vehicleModels).insert(entry);
      return true;
    } catch (e) {
      print('Error adding vehicle model: $e');
      return false; // Return false on error (e.g., unique constraint violation)
    }
  }

  /// Updates an existing vehicle model in the database based on its composite primary key.
  Future<bool> updateVehicleModel(VehicleModel modelToUpdate) async {
    // For updating a composite primary key, use 'replace' if the entire object
    // including the primary key fields correctly identifies the row.
    // If you only want to update non-PK fields, you'd use update().where().write().
    // Assuming modelToUpdate contains the original make/model to identify the row.
    final updatedCount = await _db.update(_db.vehicleModels).replace(modelToUpdate);
    return updatedCount; // Returns true if a row was updated, false otherwise.
  }

  /// Deletes a vehicle model by its composite primary key (make and model).
  Future<bool> deleteVehicleModel(String make, String model) async {
    final count = await (_db.delete(_db.vehicleModels)
          ..where((vm) => vm.make.equals(make) & vm.model.equals(model)))
        .go();
    return count > 0;
  }

  /// Populates the VehicleModels table from a JSON asset file if it's empty.
  /// It expects JSON data with 'make', 'model', 'yearFrom', and 'yearTo' (optional) fields.
  Future<void> seedDefaultVehicleModels(String assetPath) async {
    final count = await _db.select(_db.vehicleModels).get().then((list) => list.length);
    if (count > 0) {
      print('VehicleModels table already populated. Skipping seeding.');
      return;
    }

    try {
      final String response = await rootBundle.loadString(assetPath);
      final List<dynamic> data = jsonDecode(response);

      for (var item in data) {
        if (item is Map<String, dynamic>) {
          await _db.into(_db.vehicleModels).insert(
            VehicleModelsCompanion.insert(
              make: item['make'] as String,
              model: item['model'] as String,
              yearFrom: Value(item['yearFrom'] as int?),
              yearTo: Value(item['yearTo'] as int?),
            )
          );
        }
      }
      print('Successfully seeded default vehicle models from $assetPath.');
    } catch (e) {
      print('Error seeding vehicle models: $e');
    }
  }
}

