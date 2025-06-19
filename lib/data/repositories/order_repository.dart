// lib/data/repositories/order_repository.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'
    hide
        Column; // Keep hide Column to avoid conflict if other imports are added
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // For appDatabaseProvider
import 'package:autoshop_manager/data/repositories/inventory_repository.dart'; // To decrement stock

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    ref.read(appDatabaseProvider),
    ref.read(inventoryRepositoryProvider), // Inject InventoryRepository
  );
});

class OrderRepository {
  final AppDatabase _db;
  final InventoryRepository _inventoryRepo;

  OrderRepository(this._db, this._inventoryRepo);

  /// Creates a new order and its associated order items, then decrements inventory.
  Future<bool> createOrder({
    required int customerId,
    required List<Map<String, dynamic>>
    items, // {itemId: int, quantity: int, priceAtSale: double}
  }) async {
    return _db.transaction(() async {
      try {
        double totalAmount = 0.0;
        for (var itemData in items) {
          totalAmount += itemData['quantity'] * itemData['priceAtSale'];
        }

        // 1. Create the Order
        final orderId = await _db
            .into(_db.orders)
            .insert(
              OrdersCompanion.insert(
                customerId: customerId,
                orderDate: DateTime.now(),
                totalAmount: Value(totalAmount),
                status: Value('Completed'), // Assuming all orders are completed upon creation for simplicity
              ),
            );

        // 2. Create Order Items and decrement inventory
        for (var itemData in items) {
          await _db.into(_db.orderItems).insert(
                OrderItemsCompanion.insert(
                  orderId: orderId,
                  itemId: itemData['itemId'] as int,
                  quantity: itemData['quantity'] as int,
                  priceAtSale: itemData['priceAtSale'] as double,
                ),
              );
          // Decrement stock for the inventory item
          final success = await _inventoryRepo.decrementStock(
            itemData['itemId'] as int,
            itemData['quantity'] as int,
          );
          if (!success) {
            // If stock decrement fails, roll back the transaction
            throw Exception('Failed to decrement stock for item ${itemData['itemId']}');
          }
        }
        return true;
      } catch (e) {
        print('Error creating order: $e');
        // If any part of the transaction fails, it will be rolled back.
        return false;
      }
    });
  }

  /// Retrieves a specific order along with its customer and all associated items (and their inventory details).
  Future<OrderWithDetails?> getOrderWithDetails(int orderId) async {
    // Use cascade operator to properly chain the where clause
    final query = _db.select(_db.orders).join([
      innerJoin(_db.customers, _db.customers.id.equalsExp(_db.orders.customerId)),
    ])..where(_db.orders.id.equals(orderId));

    final result = await query.getSingleOrNull();

    if (result == null) {
      return null;
    }

    final order = result.readTable(_db.orders);
    final customer = result.readTable(_db.customers);

    // Now fetch order items for this order and join with inventory items
    final itemQuery = _db.select(_db.orderItems).join([
      innerJoin(_db.inventoryItems, _db.inventoryItems.id.equalsExp(_db.orderItems.itemId)),
    ])..where(_db.orderItems.orderId.equals(order.id));

    final itemResults = await itemQuery.get();

    final orderItemsWithInventory = itemResults.map((row) {
      return OrderItemWithInventory(
        orderItem: row.readTable(_db.orderItems),
        inventoryItem: row.readTable(_db.inventoryItems),
      );
    }).toList();

    return OrderWithDetails(
      order: order,
      customer: customer,
      items: orderItemsWithInventory,
    );
  }

  /// Retrieves all orders with their associated customer and items.
  Future<List<OrderWithDetails>> getAllOrdersWithDetails() async { // Renamed for clarity
    final query = _db.select(_db.orders).join([
      innerJoin(_db.customers, _db.customers.id.equalsExp(_db.orders.customerId)),
    ]);

    final results = await query.get();
    final List<OrderWithDetails> ordersWithDetails = [];

    for (final row in results) {
      final order = row.readTable(_db.orders);
      final customer = row.readTable(_db.customers);

      // Fetch items for each order
      final itemQuery = _db.select(_db.orderItems).join([
        innerJoin(_db.inventoryItems, _db.inventoryItems.id.equalsExp(_db.orderItems.itemId)),
      ])..where(_db.orderItems.orderId.equals(order.id));

      final itemResults = await itemQuery.get();

      final orderItemsWithInventory = itemResults.map((itemRow) {
        return OrderItemWithInventory(
          orderItem: itemRow.readTable(_db.orderItems),
          inventoryItem: itemRow.readTable(_db.inventoryItems),
        );
      }).toList();

      ordersWithDetails.add(OrderWithDetails(
        order: order,
        customer: customer,
        items: orderItemsWithInventory,
      ));
    }
    // Sort by order date descending
    ordersWithDetails.sort((a, b) => b.order.orderDate.compareTo(a.order.orderDate));
    return ordersWithDetails;
  }

  /// Deletes an order and its associated order items.
  Future<bool> deleteOrder(int orderId) async {
    // Due to KeyAction.cascade on OrderItems, deleting the order will delete its items.
    final count = await (_db.delete(_db.orders)..where((o) => o.id.equals(orderId))).go();
    return count > 0;
  }

  /// Updates the status of an existing order.
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final order = await getOrderWithDetails(orderId);
    if (order == null) {
      return false;
    }
    final updatedOrder = order.order.copyWith(status: newStatus);
    return _db.update(_db.orders).replace(updatedOrder);
  }

  // --- Reporting Methods ---

  /// Retrieves sales data grouped by inventory item.
  Future<List<SalesByItem>> getSalesByItemReport() async {
    // Use selectOnly for aggregate queries and let Drift infer the types
    final totalQuantityColumn = _db.orderItems.quantity.sum();
    final totalRevenueColumn = (_db.orderItems.quantity.dartCast<double>() * _db.orderItems.priceAtSale).sum();

    final query = _db.selectOnly(_db.orderItems).join([
      innerJoin(_db.inventoryItems, _db.inventoryItems.id.equalsExp(_db.orderItems.itemId)),
    ]);

    query
      ..addColumns([
        _db.inventoryItems.id,
        _db.inventoryItems.name,
        totalQuantityColumn,
        totalRevenueColumn,
      ])
      ..groupBy([_db.inventoryItems.id, _db.inventoryItems.name]);

    final results = await query.get();

    return results.map((row) {
      return SalesByItem(
        itemId: row.read(_db.inventoryItems.id)!,
        itemName: row.read(_db.inventoryItems.name)!,
        totalQuantitySold: row.read(totalQuantityColumn) ?? 0,
        totalRevenue: row.read(totalRevenueColumn)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Retrieves sales data grouped by customer.
  Future<List<SalesByCustomer>> getSalesByCustomerReport() async {
    // Use selectOnly for aggregate queries and let Drift infer the types
    final totalOrdersColumn = _db.orders.id.count();
    final totalSpentColumn = _db.orders.totalAmount.sum();

    final query = _db.selectOnly(_db.orders).join([
      innerJoin(_db.customers, _db.customers.id.equalsExp(_db.orders.customerId)),
    ]);

    query
      ..addColumns([
        _db.customers.id,
        _db.customers.name,
        totalOrdersColumn,
        totalSpentColumn,
      ])
      ..groupBy([_db.customers.id, _db.customers.name]);

    final results = await query.get();

    return results.map((row) {
      return SalesByCustomer(
        customerId: row.read(_db.customers.id)!,
        customerName: row.read(_db.customers.name)!,
        totalOrders: row.read(totalOrdersColumn) ?? 0,
        totalSpent: row.read(totalSpentColumn) ?? 0.0,
      );
    }).toList();
  }
}

// Custom data class to hold joined Order, Customer, and OrderItems data
class OrderWithDetails {
  final Order order;
  final Customer customer;
  final List<OrderItemWithInventory> items;

  OrderWithDetails({
    required this.order,
    required this.customer,
    required this.items,
  });
}

// Custom data class to hold joined OrderItem and InventoryItem data
class OrderItemWithInventory {
  final OrderItem orderItem;
  final InventoryItem inventoryItem;

  OrderItemWithInventory({
    required this.orderItem,
    required this.inventoryItem,
  });
}

// Data class for Sales by Item report
class SalesByItem {
  final int itemId;
  final String itemName;
  final int totalQuantitySold;
  final double totalRevenue; // Keep as double, formatting in UI

  SalesByItem({
    required this.itemId,
    required this.itemName,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });
}

// Data class for Sales by Customer report
class SalesByCustomer {
  final int customerId;
  final String customerName;
  final int totalOrders;
  final double totalSpent; // Keep as double, formatting in UI

  SalesByCustomer({
    required this.customerId,
    required this.customerName,
    required this.totalOrders,
    required this.totalSpent,
  });
}
