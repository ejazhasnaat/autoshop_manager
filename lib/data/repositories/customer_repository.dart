// lib/data/repositories/customer_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // For appDatabaseProvider
import 'package:autoshop_manager/data/repositories/vehicle_repository.dart'; // <--- NEW IMPORT for VehicleRepository

// Custom data class to hold Customer and their Vehicles
class CustomerWithVehicles {
  final Customer customer;
  final List<Vehicle> vehicles;

  CustomerWithVehicles({required this.customer, required this.vehicles});
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    ref.read(appDatabaseProvider),
    ref.read(vehicleRepositoryProvider), // Inject VehicleRepository
  );
});

class CustomerRepository {
  final AppDatabase _db;
  final VehicleRepository _vehicleRepo; // Add VehicleRepository field

  CustomerRepository(this._db, this._vehicleRepo);

  /// Retrieves all customers, optionally with their associated vehicles.
  Future<List<CustomerWithVehicles>> getAllCustomersWithVehicles() async {
    final customers = await _db.select(_db.customers).get();
    final List<CustomerWithVehicles> result = [];

    for (final customer in customers) {
      final vehicles = await _vehicleRepo.getVehiclesByCustomerId(customer.id!);
      result.add(CustomerWithVehicles(customer: customer, vehicles: vehicles));
    }
    return result;
  }

  /// Retrieves a single customer by ID, including their associated vehicles.
  Future<CustomerWithVehicles?> getCustomerWithVehiclesById(int id) async {
    final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (customer == null) {
      return null;
    }
    final vehicles = await _vehicleRepo.getVehiclesByCustomerId(customer.id!);
    return CustomerWithVehicles(customer: customer, vehicles: vehicles);
  }

  /// Adds a new customer and their initial vehicle(s).
  Future<int> addCustomer(CustomersCompanion customerEntry, List<VehiclesCompanion> vehicleEntries) async {
    return _db.transaction(() async {
      final customerId = await _db.into(_db.customers).insert(customerEntry);

      // Add vehicles associated with the new customer
      for (var vehicleEntry in vehicleEntries) {
        await _db.into(_db.vehicles).insert(vehicleEntry.copyWith(customerId: Value(customerId)));
      }
      return customerId;
    });
  }

  /// Updates an existing customer and their vehicles.
  Future<bool> updateCustomer(Customer customer, List<Vehicle> updatedVehicles) async {
    return _db.transaction(() async {
      // 1. Update customer details
      final customerUpdated = await _db.update(_db.customers).replace(customer);

      // 2. Manage vehicles:
      //    a. Delete existing vehicles not in the updated list
      final currentVehicles = await _vehicleRepo.getVehiclesByCustomerId(customer.id!);
      final vehiclesToDelete = currentVehicles.where((v) => !updatedVehicles.any((uv) => uv.id == v.id));
      for (final vehicle in vehiclesToDelete) {
        await _vehicleRepo.deleteVehicle(vehicle.id!);
      }

      //    b. Add new vehicles or update existing ones
      for (final updatedVehicle in updatedVehicles) {
        if (updatedVehicle.id == null) {
          // New vehicle
          await _vehicleRepo.addVehicle(VehiclesCompanion.insert(
            customerId: customer.id!,
            registrationNumber: updatedVehicle.registrationNumber,
            make: Value(updatedVehicle.make),
            model: Value(updatedVehicle.model),
            year: Value(updatedVehicle.year),
          ));
        } else {
          // Existing vehicle, update it
          await _vehicleRepo.updateVehicle(updatedVehicle);
        }
      }
      return customerUpdated;
    });
  }

  /// Deletes a customer and all their associated vehicles (due to KeyAction.cascade on Vehicles table).
  Future<bool> deleteCustomer(int id) async {
    final count = await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
    return count > 0;
  }
}

