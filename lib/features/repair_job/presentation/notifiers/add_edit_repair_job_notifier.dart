// lib/features/repair_job/presentation/notifiers/add_edit_repair_job_notifier.dart
import 'dart:async';

import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:collection/collection.dart';

part 'add_edit_repair_job_notifier.freezed.dart';

@freezed
class AddEditRepairJobState with _$AddEditRepairJobState {
  const factory AddEditRepairJobState({
    @Default(true) bool isLoading,
    @Default(false) bool isSaving,
    int? jobId,
    CustomerWithVehicles? selectedCustomerWithVehicles,
    Vehicle? selectedVehicle,
    @Default([]) List<RepairJobItem> items,
    @Default('In Progress') String status,
    @Default('Normal') String priority,
    String? notes,
    @Default(true) bool isNewJob,
    RepairJob? initialJob,
    @Default([]) List<RepairJobItem> initialItems,
  }) = _AddEditRepairJobState;

  const AddEditRepairJobState._();

  bool get hasChanges {
    if (isNewJob && (selectedVehicle != null || items.isNotEmpty || notes?.isNotEmpty == true)) {
      return true;
    }
    if (initialJob == null) return false;

    final itemsChanged = !const DeepCollectionEquality().equals(items, initialItems);

    return selectedVehicle?.id != initialJob!.vehicleId ||
        status != initialJob!.status ||
        priority != initialJob!.priority ||
        notes != initialJob!.notes ||
        itemsChanged;
  }

  double get servicesTotalCost => items
      .where((item) => item.itemType == 'Service')
      .map((item) => item.unitPrice * item.quantity)
      .fold(0.0, (a, b) => a + b);

  double get partsTotalCost => items
      .where((item) => item.itemType == 'InventoryItem')
      .map((item) => item.unitPrice * item.quantity)
      .fold(0.0, (a, b) => a + b);

  double get othersTotalCost => items
      .where((item) => item.itemType == 'Other')
      .map((item) => item.unitPrice * item.quantity)
      .fold(0.0, (a, b) => a + b);

  double get totalCost => servicesTotalCost + partsTotalCost + othersTotalCost;
}

class AddEditRepairJobNotifier extends StateNotifier<AddEditRepairJobState> {
  final Ref _ref;
  final int? _jobId;

  AddEditRepairJobNotifier(this._ref, this._jobId)
      : super(AddEditRepairJobState(jobId: _jobId, isNewJob: _jobId == null)) {
    if (_jobId != null) {
      _loadExistingJob(_jobId);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadExistingJob(int? jobId) async {
    if (jobId == null) return;
    state = state.copyWith(isLoading: true);
    final db = _ref.read(appDatabaseProvider);
    final customerRepo = _ref.read(customerRepositoryProvider);
    try {
      final job = await (db.select(db.repairJobs)..where((j) => j.id.equals(jobId))).getSingle();
      final vehicle = await (db.select(db.vehicles)..where((v) => v.id.equals(job.vehicleId))).getSingle();
      final customerWithVehicles = await customerRepo.getCustomerWithVehiclesById(vehicle.customerId);
      final jobItems = await (db.select(db.repairJobItems)..where((i) => i.repairJobId.equals(jobId))).get();

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          selectedCustomerWithVehicles: customerWithVehicles,
          selectedVehicle: vehicle,
          items: jobItems,
          initialItems: jobItems,
          status: job.status,
          priority: job.priority,
          notes: job.notes,
          initialJob: job,
          isNewJob: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void setCustomer(CustomerWithVehicles customer) {
    state = state.copyWith(selectedCustomerWithVehicles: customer, selectedVehicle: null);
    if (customer.vehicles.length == 1) {
      setVehicle(customer.vehicles.first);
    }
  }

  void setVehicle(Vehicle vehicle) =>
      state = state.copyWith(selectedVehicle: vehicle);
  
  void setPriority(String newPriority) =>
      state = state.copyWith(priority: newPriority);

  bool addInventoryItem(InventoryItem item, int quantity) {
    if (item.quantity < quantity) return false;
    final newItem = RepairJobItem(id: -1, repairJobId: _jobId ?? -1, itemType: 'InventoryItem', linkedItemId: item.id, description: item.name, quantity: quantity, unitPrice: item.salePrice);
    state = state.copyWith(items: [...state.items, newItem]);
    return true;
  }

  void addServiceItem(Service service) {
    final newItem = RepairJobItem(id: -1, repairJobId: _jobId ?? -1, itemType: 'Service', linkedItemId: service.id, description: service.name, quantity: 1, unitPrice: service.price);
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void addOtherItem({required String description, required int quantity, required double price}) {
    final newItem = RepairJobItem(id: -1, repairJobId: _jobId ?? -1, itemType: 'Other', linkedItemId: -1, description: description, quantity: quantity, unitPrice: price);
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void incrementItemQuantity(RepairJobItem item) =>
      updateItem(item, newQuantity: item.quantity + 1);

  void updateItem(RepairJobItem itemToUpdate, {int? newQuantity, double? newPrice, String? newDescription}) {
    state = state.copyWith(items: state.items.map((item) {
      return item == itemToUpdate
          ? item.copyWith(
              quantity: newQuantity ?? item.quantity,
              unitPrice: newPrice ?? item.unitPrice,
              description: newDescription ?? item.description,
            )
          : item;
    }).toList());
  }

  void removeItem(RepairJobItem itemToRemove) =>
      state = state.copyWith(items: state.items.where((item) => item != itemToRemove).toList());

  void setStatus(String newStatus) => state = state.copyWith(status: newStatus);

  void setNotes(String newNotes) => state = state.copyWith(notes: newNotes);

  Future<int?> saveJob() async {
    // --- FIX ---
    // If the state is still loading, wait for it to finish before proceeding.
    // This prevents a race condition when saveJob is called immediately after
    // the provider is initialized (e.g., from the active jobs card).
    if (state.isLoading) {
      // Wait for the next state emission that is not loading.
      await stream.firstWhere((s) => !s.isLoading);
    }

    if (state.selectedVehicle == null) {
      throw Exception('A vehicle must be selected to save a job.');
    }
    state = state.copyWith(isSaving: true);

    final db = _ref.read(appDatabaseProvider);
    final total = state.totalCost;
    
    try {
      final savedJobId = await db.transaction(() async {
        int currentJobId;
        if (state.isNewJob) {
          final jobCompanion = RepairJobsCompanion(
            vehicleId: Value(state.selectedVehicle!.id),
            creationDate: Value(DateTime.now()),
            status: Value(state.status),
            priority: Value(state.priority),
            notes: Value(state.notes ?? ''),
            totalAmount: Value(total),
          );
          currentJobId = await db.into(db.repairJobs).insert(jobCompanion);
        } else {
          if (state.initialJob == null) {
            throw Exception('Inconsistent state: Attempting to update a job but no initial job data is present.');
          }
          currentJobId = state.initialJob!.id;
          final jobCompanion = RepairJobsCompanion(
            id: Value(currentJobId),
            vehicleId: Value(state.selectedVehicle!.id),
            status: Value(state.status),
            priority: Value(state.priority),
            notes: Value(state.notes ?? ''),
            totalAmount: Value(total),
          );
          await (db.update(db.repairJobs)..where((j) => j.id.equals(currentJobId))).write(jobCompanion);
        }

        await (db.delete(db.repairJobItems)..where((i) => i.repairJobId.equals(currentJobId))).go();

        for (final item in state.items) {
          final itemCompanion = RepairJobItemsCompanion(repairJobId: Value(currentJobId), itemType: Value(item.itemType), linkedItemId: Value(item.linkedItemId), description: Value(item.description), quantity: Value(item.quantity), unitPrice: Value(item.unitPrice));
          await db.into(db.repairJobItems).insert(itemCompanion);
        }
        return currentJobId;
      });

      await _loadExistingJob(savedJobId);
      return savedJobId;

    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  Future<int?> completeAndBillJob() async {
    if (state.isLoading) {
      await stream.firstWhere((s) => !s.isLoading);
    }

    try {
      if (state.selectedVehicle == null || state.initialJob == null) {
        throw Exception('Could not load vehicle or job details for completion.');
      }

      if (mounted) {
        state = state.copyWith(isSaving: true);
      }

      final db = _ref.read(appDatabaseProvider);
      final total = state.totalCost;
      final vehicleId = state.selectedVehicle!.id;
      final now = DateTime.now();
      final currentJobId = state.initialJob!.id;
      
      final jobId = await db.transaction(() async {
        final jobCompanion = RepairJobsCompanion(
          id: Value(currentJobId),
          vehicleId: Value(vehicleId),
          completionDate: Value(now),
          status: const Value('Completed'),
          priority: Value(state.priority),
          notes: Value(state.notes ?? ''),
          totalAmount: Value(total),
        );
        await (db.update(db.repairJobs)..where((j) => j.id.equals(currentJobId))).write(jobCompanion);
        await (db.delete(db.repairJobItems)..where((i) => i.repairJobId.equals(currentJobId))).go();
        
        for (final item in state.items) {
          final itemCompanion = RepairJobItemsCompanion(
            repairJobId: Value(currentJobId),
            itemType: Value(item.itemType),
            linkedItemId: Value(item.linkedItemId),
            description: Value(item.description),
            quantity: Value(item.quantity),
            unitPrice: Value(item.unitPrice),
          );
          await db.into(db.repairJobItems).insert(itemCompanion);

          if (item.itemType == 'InventoryItem') {
            final part = await (db.select(db.inventoryItems)..where((tbl) => tbl.id.equals(item.linkedItemId))).getSingle();
            final newQuantity = part.quantity - item.quantity;
            await (db.update(db.inventoryItems)..where((tbl) => tbl.id.equals(item.linkedItemId))).write(InventoryItemsCompanion(quantity: Value(newQuantity)));
          }
        }

        final vehicle = await _ref.read(vehicleByIdProvider(vehicleId).future);
        final currentMileage = vehicle?.currentMileage ?? 0;
        await db.into(db.serviceHistories).insert(ServiceHistoriesCompanion(
          vehicleId: Value(vehicleId),
          serviceType: const Value('Repair Job'),
          serviceDate: Value(now),
          mileage: Value(currentMileage),
          repairJobId: Value(currentJobId),
        ));
        return currentJobId;
      });
      
      return jobId;
    } finally {
      //
    }
  }
}

final addEditRepairJobNotifierProvider = StateNotifierProvider.autoDispose
    .family<AddEditRepairJobNotifier, AddEditRepairJobState, int?>(
  (ref, jobId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() {
      timer?.cancel();
    });

    ref.onCancel(() {
      timer = Timer(const Duration(seconds: 30), () {
        link.close();
      });
    });

    ref.onResume(() {
      timer?.cancel();
    });

    return AddEditRepairJobNotifier(ref, jobId);
  },
);

