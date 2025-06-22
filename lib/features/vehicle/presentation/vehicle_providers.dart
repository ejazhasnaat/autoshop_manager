// lib/features/vehicle/presentation/vehicle_providers.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

// DAO Provider
final vehicleDaoProvider = Provider<VehicleDao>((ref) {
  return ref.watch(appDatabaseProvider).vehicleDao;
});

// State Notifier for Vehicle operations
class VehicleNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  final VehicleDao _vehicleDao;

  VehicleNotifier(this._vehicleDao) : super(const AsyncValue.loading());

  Future<bool> addVehicle(VehiclesCompanion vehicle) async {
    try {
      // --- DEBUGGING: Log that we are attempting to add a vehicle ---
      print('Attempting to add vehicle: ${vehicle.registrationNumber.value}');
      await _vehicleDao.insertVehicle(vehicle);
      print('Vehicle added successfully.');
      return true;
    } catch (e) {
      // --- DEBUGGING: Print the specific error if the save fails ---
      print('ERROR in addVehicle: $e');
      return false;
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      // --- DEBUGGING: Log that we are attempting to update a vehicle ---
      print('Attempting to update vehicle ID: ${vehicle.id}');
      await _vehicleDao.updateVehicle(vehicle);
      print('Vehicle updated successfully.');
      return true;
    } catch (e) {
      // --- DEBUGGING: Print the specific error if the save fails ---
      print('ERROR in updateVehicle: $e');
      return false;
    }
  }
}

final vehicleNotifierProvider =
    StateNotifierProvider<VehicleNotifier, AsyncValue<List<Vehicle>>>(
        (ref) => VehicleNotifier(ref.watch(vehicleDaoProvider)));

// Provider to get a single vehicle by its ID
final vehicleByIdProvider =
    FutureProvider.family<Vehicle?, int>((ref, vehicleId) {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.getVehicleById(vehicleId);
});
