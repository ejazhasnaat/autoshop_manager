// lib/data/repositories/inventory_repository.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // For appDatabaseProvider

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(appDatabaseProvider));
});

class InventoryRepository {
  final AppDatabase _db;

  InventoryRepository(this._db);

  /// Retrieves all inventory items, optionally filtered by vehicle make, model, and year,
  /// and supports global search across common fields, with sorting.
  Future<List<InventoryItem>> getAllInventoryItems({
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear, // Search for items covering this specific year
    String? searchTerm, // Global search term for name/partNumber/supplier/stockLocation
    String? sortBy, // Field to sort by (e.g., 'name', 'quantity')
    bool sortAscending = true,
  }) async {
    final query = _db.select(_db.inventoryItems);
    List<Expression<bool>> whereClauses = [];

    // Global Search Term for multiple fields
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final lowerSearchTerm = searchTerm.toLowerCase();
      whereClauses.add(
        _db.inventoryItems.name.lower().like('%$lowerSearchTerm%') |
        _db.inventoryItems.partNumber.lower().like('%$lowerSearchTerm%') |
        _db.inventoryItems.supplier.lower().like('%$lowerSearchTerm%') |
        _db.inventoryItems.stockLocation.lower().like('%$lowerSearchTerm%'),
      );
    }

    // Vehicle specific filters
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      whereClauses.add(_db.inventoryItems.vehicleMake.equals(vehicleMake));
    }
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      whereClauses.add(_db.inventoryItems.vehicleModel.equals(vehicleModel));
    }
    if (vehicleYear != null) {
      whereClauses.add(
        (_db.inventoryItems.vehicleYearFrom.isNull() | _db.inventoryItems.vehicleYearFrom.isSmallerOrEqualValue(vehicleYear)) &
        (_db.inventoryItems.vehicleYearTo.isNull() | _db.inventoryItems.vehicleYearTo.isBiggerOrEqualValue(vehicleYear)),
      );
    }

    if (whereClauses.isNotEmpty) {
      query.where((tbl) => whereClauses.reduce((value, element) => value & element));
    }

    // Sorting
    // <--- FIX: Wrap OrderingTerm with a function that takes the table and returns the OrderingTerm --->
    if (sortBy != null && sortBy.isNotEmpty) {
      query.orderBy([(tbl) {
        switch (sortBy) {
          case 'name':
            return OrderingTerm(expression: tbl.name, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          case 'partNumber':
            return OrderingTerm(expression: tbl.partNumber, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          case 'quantity':
            return OrderingTerm(expression: tbl.quantity, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          case 'salePrice':
            return OrderingTerm(expression: tbl.salePrice, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          case 'supplier':
            return OrderingTerm(expression: tbl.supplier, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          case 'stockLocation':
            return OrderingTerm(expression: tbl.stockLocation, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc);
          default:
            return OrderingTerm(expression: tbl.name, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc); // Default sort
        }
      }]);
    } else {
      query.orderBy([ (tbl) => OrderingTerm(expression: tbl.name) ]); // Default sort if no sortBy specified
    }

    return query.get();
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

  Future<bool> deleteInventoryItem(int itemId) async {
    final existingOrderItems = await (_db.select(_db.orderItems)
          ..where((oi) => oi.itemId.equals(itemId)))
        .get();

    if (existingOrderItems.isNotEmpty) {
      print('Cannot delete inventory item $itemId: It is part of existing orders.');
      return false;
    }

    final count = await (_db.delete(_db.inventoryItems)..where((t) => t.id.equals(itemId))).go();
    return count > 0;
  }
}

