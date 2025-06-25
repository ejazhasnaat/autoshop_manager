// lib/features/customer/presentation/customer_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:drift/drift.dart';


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
      await _fetchCustomers();
      return true;
    } catch (e) {
      print('Error adding customer: $e');
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final success = await _repository.updateCustomer(customer);
      if (success) {
        await _fetchCustomers();
      }
      return success;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  // OPTIMIZATION: Updated deleteCustomer for a more responsive UI.
  Future<bool> deleteCustomer(int id) async {
    // Keep the current state to revert back to in case of an error.
    final previousState = state;
    try {
      // Immediately update the state locally for a snappy UI response.
      state.whenData((customers) {
        final updatedList = customers.where((c) => c.customer.id != id).toList();
        state = AsyncValue.data(updatedList);
      });

      // Then, call the repository to delete from the database.
      final success = await _repository.deleteCustomer(id);
      
      // If the database operation fails, revert the state.
      if (!success) {
        state = previousState;
        return false;
      }
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      // Revert state on any exception.
      state = previousState;
      return false;
    }
  }
  
  // NEW METHOD: Added to support vehicle deletion from the edit customer screen.
  Future<bool> deleteVehicle(int vehicleId) async {
    try {
      // This relies on a `deleteVehicle` method in your CustomerRepository.
      final success = await _repository.deleteVehicle(vehicleId);
      // No need to call _fetchCustomers here, as the screen that calls this
      // will invalidate the specific customer provider to refresh its vehicle list.
      return success;
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }
}
