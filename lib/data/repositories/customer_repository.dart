// lib/data/repositories/customer_repository.dart
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- FIX: Import the equatable package ---
import 'package:equatable/equatable.dart';

// Custom data class to hold Customer and their Vehicles
// --- FIX: Extend Equatable to allow for proper object comparison ---
class CustomerWithVehicles extends Equatable {
  final Customer customer;
  final List<Vehicle> vehicles;

  // --- FIX: Added 'const' for performance optimization ---
  const CustomerWithVehicles({required this.customer, required this.vehicles});

  // --- FIX: This tells Dart to compare two instances by the customer's ID ---
  @override
  List<Object?> get props => [customer.id];
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    ref.watch(appDatabaseProvider),
    ref.read(vehicleRepositoryProvider),
  );
});

class CustomerRepository {
  final AppDatabase _db;
  final VehicleRepository _vehicleRepo;

  CustomerRepository(this._db, this._vehicleRepo);

  Future<List<CustomerWithVehicles>> getAllCustomersWithVehicles() async {
    final customers = await _db.select(_db.customers).get();
    final List<CustomerWithVehicles> result = [];

    for (final customer in customers) {
      // Assuming customer.id is not null for existing customers
      final vehicles = await _vehicleRepo.getVehiclesByCustomerId(customer.id);
      result.add(CustomerWithVehicles(customer: customer, vehicles: vehicles));
    }
    return result;
  }

  Future<CustomerWithVehicles?> getCustomerWithVehiclesById(int id) async {
    final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (customer == null) {
      return null;
    }
    final vehicles = await _vehicleRepo.getVehiclesByCustomerId(customer.id);
    return CustomerWithVehicles(customer: customer, vehicles: vehicles);
  }

  Future<int> addCustomer(CustomersCompanion customerEntry, List<VehiclesCompanion> vehicleEntries) async {
    return _db.transaction(() async {
      final customerId = await _db.into(_db.customers).insert(customerEntry);
      for (var vehicleEntry in vehicleEntries) {
        await _db.into(_db.vehicles).insert(vehicleEntry.copyWith(customerId: Value(customerId)));
      }
      return customerId;
    });
  }

  Future<bool> updateCustomer(Customer customer) async {
    return _db.transaction(() async {
      final success = await _db.update(_db.customers).replace(customer);
      return success;
    });
  }

  Future<bool> deleteCustomer(int id) async {
    final count = await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
    return count > 0;
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    return _vehicleRepo.deleteVehicle(vehicleId);
  }
}
