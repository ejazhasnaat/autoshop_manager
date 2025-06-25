import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:autoshop_manager/data/repositories/vehicle_model_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/data/database/app_database.dart';

// --- MAIN PROVIDER FOR UI DROPDOWNS ---
// This provider now loads the vehicle models directly from the JSON asset file.
// This is what the "Add Vehicle" screen will use to populate the dropdowns.
final vehicleModelListProvider = FutureProvider.autoDispose<List<VehicleModel>>((ref) async {
  try {
    // Load the JSON string from the asset bundle
    final jsonString = await rootBundle.loadString('assets/vehicle_models.json');
    
    // Decode the JSON string into a list of dynamic objects
    final List<dynamic> jsonList = json.decode(jsonString);
    
    // Map the JSON list to a list of VehicleModel data classes.
    // Drift's generated .fromJson constructor handles this perfectly.
    final models = jsonList.map((json) => VehicleModel.fromJson(json)).toList();
    
    return models;
  } catch (e) {
    // If anything goes wrong (file not found, JSON format error),
    // we throw an exception that will be caught by the .when() in the UI.
    print('Failed to load vehicle models: $e');
    throw Exception('Could not load vehicle models from JSON.');
  }
});


// --- DATABASE-RELATED PROVIDERS ---
// The Notifier and Repository below are for managing models if you were
// to store them in the database (e.g., if users could add/edit models from a different screen).

// StateNotifierProvider for managing the list of vehicle models stored in the database
final vehicleModelNotifierProvider = StateNotifierProvider.autoDispose<VehicleModelNotifier, AsyncValue<List<VehicleModel>>>((ref) {
  return VehicleModelNotifier(ref.read(vehicleModelRepositoryProvider));
});

// FutureProvider.family to get a single vehicle model from the database by make and model
final vehicleModelByMakeModelProvider = FutureProvider.family.autoDispose<VehicleModel?, (String, String)>((ref, makeModelTuple) async {
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
