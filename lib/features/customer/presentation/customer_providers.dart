// lib/features/customer/presentation/customer_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Customer and CustomersCompanion
import 'package:autoshop_manager/data/repositories/customer_repository.dart'; // <--- ADD THIS IMPORT: For CustomerRepository and CustomerWithVehicles
import 'package:drift/drift.dart'; // For Value (needed for add/update Customer methods if they use Companions directly)


// StateNotifierProvider for managing the list of customers with their vehicles
final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerWithVehicles>>>((ref) {
  return CustomerNotifier(ref.read(customerRepositoryProvider));
});

// FutureProvider to expose a single customer with their vehicles by ID
final customerByIdProvider = FutureProvider.family<CustomerWithVehicles?, int>((ref, id) async {
  final repository = ref.read(customerRepositoryProvider);
  return repository.getCustomerWithVehiclesById(id);
});

// Provider to expose the list of customers with vehicles from the notifier's state
final customerListProvider = Provider<AsyncValue<List<CustomerWithVehicles>>>((ref) {
  return ref.watch(customerNotifierProvider);
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerWithVehicles>>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      state = const AsyncValue.loading();
      final customers = await _repository.getAllCustomersWithVehicles();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addCustomer(CustomersCompanion customerEntry, List<VehiclesCompanion> vehicleEntries) async {
    try {
      await _repository.addCustomer(customerEntry, vehicleEntries);
      await _fetchCustomers(); // Refresh the list
      return true;
    } catch (e) {
      print('Error adding customer: $e');
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      // The repository method will also need this simplification.
      final success = await _repository.updateCustomer(customer);
      if (success) {
        await _fetchCustomers(); // Refresh the list
      }
      return success;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final success = await _repository.deleteCustomer(id);
      if (success) {
        await _fetchCustomers(); // Refresh the list
      }
      return success;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  // searchCustomers method is not implemented in the repository, so it's commented out.
  /*
  Future<void> searchCustomers(String query) async {
    try {
      state = const AsyncValue.loading();
      // Assuming CustomerRepository has a search method that returns CustomerWithVehicles
      final customers = await _repository.searchCustomers(query);
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  */
}

