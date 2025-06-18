// lib/features/vehicle_model/presentation/vehicle_model_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column; // For Value and Companion types
import 'package:autoshop_manager/data/database/app_database.dart'; // For VehicleModel and VehicleModelsCompanion
import 'package:autoshop_manager/data/repositories/vehicle_model_repository.dart'; // For VehicleModelRepository


// StateNotifierProvider for managing the list of vehicle models
final vehicleModelNotifierProvider = StateNotifierProvider<VehicleModelNotifier, AsyncValue<List<VehicleModel>>>((ref) {
  return VehicleModelNotifier(ref.read(vehicleModelRepositoryProvider));
});

// FutureProvider to expose the list of vehicle models from the notifier's state
final vehicleModelListProvider = Provider<AsyncValue<List<VehicleModel>>>((ref) {
  return ref.watch(vehicleModelNotifierProvider);
});

// FutureProvider.family to get a single vehicle model by make and model (composite key)
final vehicleModelByMakeModelProvider = FutureProvider.family<VehicleModel?, (String, String)>((ref, makeModelTuple) async {
  final make = makeModelTuple.$1;
  final model = makeModelTuple.$2;
  return ref.read(vehicleModelRepositoryProvider).getVehicleModelByMakeModel(make, model);
});


class VehicleModelNotifier extends StateNotifier<AsyncValue<List<VehicleModel>>> {
  final VehicleModelRepository _repository;

  VehicleModelNotifier(this._repository) : super(const AsyncValue.loading()) {
    _fetchVehicleModels();
  }

  // Fetches all vehicle models from the repository and updates the state
  Future<void> _fetchVehicleModels() async {
    try {
      state = const AsyncValue.loading();
      final models = await _repository.getAllVehicleModels();
      state = AsyncValue.data(models);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Adds a new vehicle model
  Future<bool> addVehicleModel(VehicleModelsCompanion entry) async {
    try {
      await _repository.addVehicleModel(entry);
      await _fetchVehicleModels(); // Refresh list after adding
      return true;
    } catch (e) {
      print('Error adding vehicle model: $e');
      return false;
    }
  }

  // Updates an existing vehicle model
  Future<bool> updateVehicleModel(VehicleModel vehicleModel) async {
    try {
      final success = await _repository.updateVehicleModel(vehicleModel);
      if (success) {
        await _fetchVehicleModels(); // Refresh list after updating
      }
      return success;
    } catch (e) {
      print('Error updating vehicle model: $e');
      return false;
    }
  }

  // Deletes a vehicle model by make and model
  Future<bool> deleteVehicleModel(String make, String model) async {
    try {
      final success = await _repository.deleteVehicleModel(make, model);
      if (success) {
        await _fetchVehicleModels(); // Refresh list after deleting
      }
      return success;
    } catch (e) {
      print('Error deleting vehicle model: $e');
      return false;
    }
  }
}

