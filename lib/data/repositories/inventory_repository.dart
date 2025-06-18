// lib/data/repositories/inventory_repository.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column; // Keep hide Column if needed
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // <--- NEW IMPORT for appDatabaseProvider

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(appDatabaseProvider));
});

class InventoryRepository {
  final AppDatabase _db;

  InventoryRepository(this._db);

  Future<List<InventoryItem>> getAllInventoryItems() async {
    return _db.select(_db.inventoryItems).get();
  }

  Future<InventoryItem?> getInventoryItemById(int id) async {
    return (_db.select(_db.inventoryItems)..where((item) => item.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addInventoryItem(InventoryItemsCompanion entry) async {
    return _db.into(_db.inventoryItems).insert(entry);
  }

  Future<bool> updateInventoryItem(InventoryItem item) async {
    return _db.update(_db.inventoryItems).replace(item);
  }

  // Method to decrement stock for an item
  Future<bool> decrementStock(int itemId, int quantityToDecrement) async {
    final item = await getInventoryItemById(itemId);
    if (item == null || item.quantity < quantityToDecrement) {
      return false; // Not enough stock or item not found
    }

    final updatedQuantity = item.quantity - quantityToDecrement;
    final success = await _db.update(_db.inventoryItems).replace(
          item.copyWith(quantity: updatedQuantity),
        );
    return success;
  }

  // Method to delete an inventory item
  Future<bool> deleteInventoryItem(int itemId) async {
    // Check if the item is part of any existing order items (due to KeyAction.restrict)
    final existingOrderItems = await (_db.select(_db.orderItems)
          ..where((oi) => oi.itemId.equals(itemId)))
        .get();

    if (existingOrderItems.isNotEmpty) {
      // If there are existing order items, we cannot delete due to foreign key constraint.
      // You might want to throw an exception or return false and handle this in UI.
      print('Cannot delete inventory item $itemId: It is part of existing orders.');
      return false;
    }

    final count = await (_db.delete(_db.inventoryItems)..where((t) => t.id.equals(itemId))).go();
    return count > 0;
  }
}

