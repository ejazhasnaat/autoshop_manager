// lib/features/inventory/presentation/inventory_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/inventory_repository.dart';

final inventoryNotifierProvider = StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>((ref) {
  return InventoryNotifier(ref.read(inventoryRepositoryProvider));
});

final inventoryItemByIdProvider = FutureProvider.family<InventoryItem?, int>((ref, itemId) async {
  return ref.read(inventoryRepositoryProvider).getInventoryItemById(itemId);
});

// The provider to be watched in InventoryListScreen and AddEditOrderScreen
// It directly exposes the state of the InventoryNotifier.
final inventoryListProvider = Provider<AsyncValue<List<InventoryItem>>>((ref) {
  return ref.watch(inventoryNotifierProvider);
});


class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final InventoryRepository _inventoryRepository;

  InventoryNotifier(this._inventoryRepository) : super(const AsyncValue.loading()) {
    _fetchInventoryItems();
  }

  Future<void> _fetchInventoryItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _inventoryRepository.getAllInventoryItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addInventoryItem(InventoryItemsCompanion entry) async {
    try {
      await _inventoryRepository.addInventoryItem(entry);
      await _fetchInventoryItems(); // Refresh the list
      return true;
    } catch (e) {
      print('Error adding inventory item: $e');
      return false;
    }
  }

  Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      final success = await _inventoryRepository.updateInventoryItem(item);
      if (success) {
        await _fetchInventoryItems(); // Refresh the list
      }
      return success;
    } catch (e) {
      print('Error updating inventory item: $e');
      return false;
    }
  }

  // <--- NEW: Delete Inventory Item Method --->
  Future<bool> deleteInventoryItem(int itemId) async {
    try {
      final success = await _inventoryRepository.deleteInventoryItem(itemId);
      if (success) {
        await _fetchInventoryItems(); // Refresh the list
      } else {
        print('Failed to delete inventory item (possible foreign key constraint).');
      }
      return success;
    } catch (e) {
      print('Error deleting inventory item: $e');
      return false;
    }
  }
}

