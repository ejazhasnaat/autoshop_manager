// lib/features/service/presentation/service_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Service and ServicesCompanion
import 'package:autoshop_manager/data/repositories/service_repository.dart'; // For ServiceRepository

// StateNotifierProvider for managing the list of services
final serviceNotifierProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<Service>>>((ref) {
  return ServiceNotifier(ref.read(serviceRepositoryProvider));
});

// FutureProvider to expose the list of services from the notifier's state
final serviceListProvider = Provider<AsyncValue<List<Service>>>((ref) {
  return ref.watch(serviceNotifierProvider);
});

// FutureProvider.family to get a single service by ID
final serviceByIdProvider = FutureProvider.family<Service?, int>((ref, serviceId) async {
  return ref.read(serviceRepositoryProvider).getServiceById(serviceId);
});

class ServiceNotifier extends StateNotifier<AsyncValue<List<Service>>> {
  final ServiceRepository _serviceRepository;

  ServiceNotifier(this._serviceRepository) : super(const AsyncValue.loading()) {
    _fetchServices();
  }

  // Fetches all services from the repository and updates the state
  Future<void> _fetchServices() async {
    try {
      state = const AsyncValue.loading();
      final services = await _serviceRepository.getAllServices();
      state = AsyncValue.data(services);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Adds a new service
  Future<bool> addService(ServicesCompanion entry) async {
    try {
      await _serviceRepository.addService(entry);
      await _fetchServices(); // Refresh list after adding
      return true;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  // Updates an existing service
  Future<bool> updateService(Service service) async {
    try {
      final success = await _serviceRepository.updateService(service);
      if (success) {
        await _fetchServices(); // Refresh list after updating
      }
      return success;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Deletes a service by ID
  Future<bool> deleteService(int id) async {
    try {
      final success = await _serviceRepository.deleteService(id);
      if (success) {
        await _fetchServices(); // Refresh list after deleting
      }
      return success;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }
}

