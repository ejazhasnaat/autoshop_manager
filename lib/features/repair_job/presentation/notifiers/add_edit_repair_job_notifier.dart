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
    String? notes,
    @Default(true) bool isNewJob,
    RepairJob? initialJob,
  }) = _AddEditRepairJobState;

  const AddEditRepairJobState._();

  double get servicesTotalCost {
    if (items.isEmpty) return 0.0;
    return items
        .where((item) => item.itemType == 'Service')
        .map((item) => item.unitPrice * item.quantity)
        .fold(0.0, (a, b) => a + b);
  }

  double get partsTotalCost {
    if (items.isEmpty) return 0.0;
    return items
        .where((item) => item.itemType == 'InventoryItem')
        .map((item) => item.unitPrice * item.quantity)
        .fold(0.0, (a, b) => a + b);
  }

  // --- RENAMED: from extrasTotalCost to othersTotalCost and updated filter ---
  double get othersTotalCost {
    if (items.isEmpty) return 0.0;
    return items
        .where((item) => item.itemType == 'Other')
        .map((item) => item.unitPrice * item.quantity)
        .fold(0.0, (a, b) => a + b);
  }

  // --- UPDATED: Grand total now includes the cost of other items ---
  double get totalCost {
    return servicesTotalCost + partsTotalCost + othersTotalCost;
  }
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

  Future<void> _loadExistingJob(int jobId) async {
    state = state.copyWith(isLoading: true);
    final db = _ref.read(appDatabaseProvider);
    final customerRepo = _ref.read(customerRepositoryProvider);
    try {
      final job = await (db.select(db.repairJobs)..where((j) => j.id.equals(jobId))).getSingle();
      final vehicle = await (db.select(db.vehicles)..where((v) => v.id.equals(job.vehicleId))).getSingle();
      final customerWithVehicles = await customerRepo.getCustomerWithVehiclesById(vehicle.customerId);

      state = state.copyWith(
        isLoading: false,
        selectedCustomerWithVehicles: customerWithVehicles,
        selectedVehicle: vehicle,
        items: await (db.select(db.repairJobItems)..where((i) => i.repairJobId.equals(jobId))).get(),
        status: job.status,
        notes: job.notes,
        initialJob: job,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setCustomer(CustomerWithVehicles customer) {
    state = state.copyWith(selectedCustomerWithVehicles: customer, selectedVehicle: null);
  }

  void setVehicle(Vehicle vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  bool addInventoryItem(InventoryItem item, int quantity) {
    if (item.quantity < quantity) {
      return false;
    }
    final newItem = RepairJobItem(
      id: -1,
      repairJobId: _jobId ?? -1,
      itemType: 'InventoryItem',
      linkedItemId: item.id,
      description: item.name,
      quantity: quantity,
      unitPrice: item.salePrice,
    );
    state = state.copyWith(items: [...state.items, newItem]);
    return true;
  }

  void addServiceItem(Service service) {
    final newItem = RepairJobItem(
      id: -1,
      repairJobId: _jobId ?? -1,
      itemType: 'Service',
      linkedItemId: service.id,
      description: service.name,
      quantity: 1,
      unitPrice: service.price,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  // --- RENAMED: from addExtraItem to addOtherItem and updated itemType ---
  void addOtherItem({
    required String description,
    required int quantity,
    required double price,
  }) {
    final newItem = RepairJobItem(
      id: -1, 
      repairJobId: _jobId ?? -1,
      itemType: 'Other',
      linkedItemId: -1,
      description: description,
      quantity: quantity,
      unitPrice: price,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void incrementItemQuantity(RepairJobItem item) {
    final newQty = item.quantity + 1;
    updateItem(item, newQuantity: newQty);
  }

  // --- UPDATED: The updateItem method now accepts an optional description ---
  void updateItem(
      RepairJobItem itemToUpdate, {int? newQuantity, double? newPrice, String? newDescription}) {
    final updatedItems = state.items.map((item) {
      if (item == itemToUpdate) {
        return item.copyWith(
          quantity: newQuantity ?? item.quantity,
          unitPrice: newPrice ?? item.unitPrice,
          // If a new description is provided, use it, otherwise keep the old one.
          description: newDescription ?? item.description,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(RepairJobItem itemToRemove) {
    final updatedItems =
        state.items.where((item) => item != itemToRemove).toList();
    state = state.copyWith(items: updatedItems);
  }

  void setStatus(String newStatus) {
    state = state.copyWith(status: newStatus);
  }

  void setNotes(String newNotes) {
    state = state.copyWith(notes: newNotes);
  }

  Future<int?> saveJob() async {
    if (state.selectedVehicle == null) {
      throw Exception('A vehicle must be selected to save a job.');
    }
    state = state.copyWith(isSaving: true);

    final db = _ref.read(appDatabaseProvider);
    final total = state.totalCost;
    
    try {
      return await db.transaction(() async {
        int savedJobId;

        if (state.isNewJob) {
          final jobCompanion = RepairJobsCompanion(
            vehicleId: Value(state.selectedVehicle!.id),
            creationDate: Value(DateTime.now()),
            status: Value(state.status),
            notes: Value(state.notes ?? ''),
            totalAmount: Value(total),
          );
          savedJobId = await db.into(db.repairJobs).insert(jobCompanion);
          state = state.copyWith(jobId: savedJobId, isNewJob: false);
        } else {
          savedJobId = _jobId!;
          final jobCompanion = RepairJobsCompanion(
            id: Value(savedJobId),
            vehicleId: Value(state.selectedVehicle!.id),
            status: Value(state.status),
            notes: Value(state.notes ?? ''),
            totalAmount: Value(total),
          );
          await (db.update(db.repairJobs)..where((j) => j.id.equals(savedJobId))).write(jobCompanion);
        }

        await (db.delete(db.repairJobItems)..where((i) => i.repairJobId.equals(savedJobId))).go();

        for (final item in state.items) {
          final itemCompanion = RepairJobItemsCompanion(
            repairJobId: Value(savedJobId),
            itemType: Value(item.itemType),
            linkedItemId: Value(item.linkedItemId),
            description: Value(item.description),
            quantity: Value(item.quantity),
            unitPrice: Value(item.unitPrice),
          );
          await db.into(db.repairJobItems).insert(itemCompanion);
        }
        
        return savedJobId;
      });
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<int?> completeAndBillJob() async {
    if (state.selectedVehicle == null) {
      throw Exception('A vehicle must be selected to save a job.');
    }

    state = state.copyWith(isSaving: true);
    final db = _ref.read(appDatabaseProvider);
    final total = state.totalCost;
    final vehicleId = state.selectedVehicle!.id;
    final now = DateTime.now();

    try {
      return await db.transaction(() async {
        final jobCompanion = RepairJobsCompanion(
          id: Value(_jobId!),
          vehicleId: Value(vehicleId),
          completionDate: Value(now),
          status: const Value('Completed'),
          notes: Value(state.notes ?? ''),
          totalAmount: Value(total),
        );

        await (db.update(db.repairJobs)..where((j) => j.id.equals(_jobId!))).write(jobCompanion);

        await (db.delete(db.repairJobItems)..where((i) => i.repairJobId.equals(_jobId!))).go();
        
        for (final item in state.items) {
          final itemCompanion = RepairJobItemsCompanion(
            repairJobId: Value(_jobId!),
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
            await (db.update(db.inventoryItems)..where((tbl) => tbl.id.equals(item.linkedItemId))).write(
                InventoryItemsCompanion(quantity: Value(newQuantity)));
          }
        }

        final vehicle = await _ref.read(vehicleByIdProvider(vehicleId).future);
        final currentMileage = vehicle?.currentMileage ?? 0;

        await db.into(db.serviceHistories).insert(ServiceHistoriesCompanion(
              vehicleId: Value(vehicleId),
              serviceType: const Value('Repair Job'),
              serviceDate: Value(now),
              mileage: Value(currentMileage),
              repairJobId: Value(_jobId!),
            ));

        _ref.invalidate(activeRepairJobsProvider);
        _ref.invalidate(activeRepairJobCountProvider);

        return _jobId;
      });
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final addEditRepairJobNotifierProvider = StateNotifierProvider.autoDispose
    .family<AddEditRepairJobNotifier, AddEditRepairJobState, int?>(
  (ref, jobId) => AddEditRepairJobNotifier(ref, jobId),
);

