// lib/features/inventory/presentation/inventory_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/inventory_repository.dart';
import 'package:drift/drift.dart' hide Column; // For Value

// Combined state for all inventory list filters and sorting
class InventoryListFilterState {
  final String? make;
  final String? model;
  final int? year;
  final String? searchTerm;
  final String? sortBy; // e.g., 'name', 'quantity'
  final bool sortAscending;

  InventoryListFilterState({
    this.make,
    this.model,
    this.year,
    this.searchTerm,
    this.sortBy = 'name', // Default sort by name
    this.sortAscending = true,
  });

  InventoryListFilterState copyWith({
    String? make,
    String? model,
    int? year,
    String? searchTerm,
    String? sortBy,
    bool? sortAscending,
  }) {
    return InventoryListFilterState(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      searchTerm: searchTerm ?? this.searchTerm,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

// StateProvider to hold the current filters and sorting parameters
final inventoryListFilterStateProvider = StateProvider<InventoryListFilterState>((ref) {
  return InventoryListFilterState();
});

// StateNotifierProvider for managing the list of inventory items
final inventoryNotifierProvider = StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>((ref) {
  return InventoryNotifier(ref.read(inventoryRepositoryProvider), ref); // Pass ref here
});


class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final InventoryRepository _repository;
  final Ref _ref; // Store Ref

  InventoryNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    // Initial fetch, use the default filters from the StateProvider
    final initialFilters = _ref.read(inventoryListFilterStateProvider);
    _fetchInventoryItems(
      searchTerm: initialFilters.searchTerm,
      vehicleMake: initialFilters.make,
      vehicleModel: initialFilters.model,
      vehicleYear: initialFilters.year,
      sortBy: initialFilters.sortBy,
      sortAscending: initialFilters.sortAscending,
    );
  }

  Future<void> _fetchInventoryItems({
    String? searchTerm,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.getAllInventoryItems(
        searchTerm: searchTerm,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyFiltersAndSort({
    String? searchTerm,
    String? make,
    String? model,
    int? year,
    String? sortBy,
    bool? sortAscending,
  }) {
    _ref.read(inventoryListFilterStateProvider.notifier).update((state) {
      return state.copyWith(
        make: make,
        model: model,
        year: year,
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );
    });
    final currentFilters = _ref.read(inventoryListFilterStateProvider);
    _fetchInventoryItems(
      searchTerm: currentFilters.searchTerm,
      vehicleMake: currentFilters.make,
      vehicleModel: currentFilters.model,
      vehicleYear: currentFilters.year,
      sortBy: currentFilters.sortBy,
      sortAscending: currentFilters.sortAscending,
    );
  }

  Future<bool> addInventoryItem(InventoryItemsCompanion entry) async {
    try {
      await _repository.addInventoryItem(entry);
      // --- FIX: Directly refetch the list with current filters ---
      final currentFilters = _ref.read(inventoryListFilterStateProvider);
      await _fetchInventoryItems(
        searchTerm: currentFilters.searchTerm,
        vehicleMake: currentFilters.make,
        vehicleModel: currentFilters.model,
        vehicleYear: currentFilters.year,
        sortBy: currentFilters.sortBy,
        sortAscending: currentFilters.sortAscending,
      );
      return true;
    } catch (e, st) {
      // --- FIX: Propagate error to the UI ---
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      final success = await _repository.updateInventoryItem(item);
      if (success) {
        // --- FIX: Directly refetch the list with current filters ---
        final currentFilters = _ref.read(inventoryListFilterStateProvider);
        await _fetchInventoryItems(
          searchTerm: currentFilters.searchTerm,
          vehicleMake: currentFilters.make,
          vehicleModel: currentFilters.model,
          vehicleYear: currentFilters.year,
          sortBy: currentFilters.sortBy,
          sortAscending: currentFilters.sortAscending,
        );
      }
      return success;
    } catch (e, st) {
      // --- FIX: Propagate error to the UI ---
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteInventoryItem(int itemId) async {
    try {
      final success = await _repository.deleteInventoryItem(itemId);
      if (success) {
        // --- FIX: Directly refetch the list with current filters ---
        final currentFilters = _ref.read(inventoryListFilterStateProvider);
        await _fetchInventoryItems(
          searchTerm: currentFilters.searchTerm,
          vehicleMake: currentFilters.make,
          vehicleModel: currentFilters.model,
          vehicleYear: currentFilters.year,
          sortBy: currentFilters.sortBy,
          sortAscending: currentFilters.sortAscending,
        );
      }
      return success;
    } catch (e, st) {
      // --- FIX: Propagate error to the UI ---
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

