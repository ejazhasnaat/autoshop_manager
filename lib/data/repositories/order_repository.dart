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
                orderDate: DateTime.now(), // Explicitly set current date/time
                totalAmount: Value(totalAmount),
                status: Value('Pending'), // Initial status
              ),
            );

        // 2. Add Order Items and Decrement Inventory
        for (var itemData in items) {
          final itemId = itemData['itemId'] as int;
          final quantity = itemData['quantity'] as int;
          final priceAtSale = itemData['priceAtSale'] as double;

          // Check if sufficient stock exists before proceeding
          final inventoryItem = await _inventoryRepo.getInventoryItemById(
            itemId,
          );
          if (inventoryItem == null || inventoryItem.quantity < quantity) {
            throw Exception('Insufficient stock for item ID: $itemId');
          }

          // Add item to OrderItems
          await _db
              .into(_db.orderItems)
              .insert(
                OrderItemsCompanion.insert(
                  orderId: orderId,
                  itemId: itemId,
                  quantity: quantity,
                  priceAtSale: priceAtSale,
                ),
              );

          // Decrement inventory stock
          final success = await _inventoryRepo.decrementStock(itemId, quantity);
          if (!success) {
            throw Exception('Failed to decrement stock for item ID: $itemId');
          }
        }
        return true;
      } catch (e) {
        print('Error creating order: $e');
        return false;
      }
    });
  }

  /// Retrieves an order by its ID, including its associated customer and items.
  Future<OrderWithDetails?> getOrderById(int orderId) async {
    // Step 1: Build the initial joined query
    final query = _db.select(_db.orders).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.orders.customerId),
      ),
    ]);

    // Step 2: Apply the where clause and execute
    final result = await (query..where(_db.orders.id.equals(orderId)))
        .getSingleOrNull();

    if (result != null) {
      final order = result.readTable(_db.orders);
      final customer = result.readTable(_db.customers);

      // Step 3: Build the sub-query for order items
      final orderItemsQuery = _db.select(_db.orderItems).join([
        innerJoin(
          _db.inventoryItems,
          _db.inventoryItems.id.equalsExp(_db.orderItems.itemId),
        ),
      ]);

      // Step 4: Apply where and map, then execute
      final orderItems =
          await (orderItemsQuery
                ..where(_db.orderItems.orderId.equals(order.id)))
              .map((row) {
                return OrderItemWithInventory(
                  orderItem: row.readTable(_db.orderItems),
                  inventoryItem: row.readTable(_db.inventoryItems),
                );
              })
              .get();

      return OrderWithDetails(
        order: order,
        customer: customer,
        items: orderItems,
      );
    }
    return null;
  }

  /// Retrieves all orders, optionally filtered by status, including customer details.
  Future<List<OrderWithDetails>> getAllOrders({String? statusFilter}) async {
    // Start building the query
    var query = _db.select(_db.orders).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.orders.customerId),
      ),
    ]);

    // Apply filter if present.
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query..where(_db.orders.status.equals(statusFilter));
    }

    // Apply ordering.
    query = query..orderBy([OrderingTerm.desc(_db.orders.orderDate)]);

    final result = await query.get();

    final List<OrderWithDetails> ordersWithDetails = [];
    for (var row in result) {
      final order = row.readTable(_db.orders);
      final customer = row.readTable(_db.customers);

      // Construct the sub-query for order items
      final orderItemsQuery = _db.select(_db.orderItems).join([
        innerJoin(
          _db.inventoryItems,
          _db.inventoryItems.id.equalsExp(_db.orderItems.itemId),
        ),
      ]);

      // Apply where and map, then execute
      final orderItems =
          await (orderItemsQuery
                ..where(_db.orderItems.orderId.equals(order.id)))
              .map((row) {
                return OrderItemWithInventory(
                  orderItem: row.readTable(_db.orderItems),
                  inventoryItem: row.readTable(_db.inventoryItems),
                );
              })
              .get();

      ordersWithDetails.add(
        OrderWithDetails(order: order, customer: customer, items: orderItems),
      );
    }
    return ordersWithDetails;
  }

  /// Updates the status of an existing order.
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final updatedRows =
        await (_db.update(_db.orders)..where((o) => o.id.equals(orderId)))
            .write(OrdersCompanion(status: Value(newStatus)));
    return updatedRows > 0;
  }

  // --- NEW REPORTING METHODS FOR PHASE 4 ---

  /// Retrieves total sales amount over a given time range.
  Future<double> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    final totalAmountColumn = _db.orders.totalAmount
        .sum(); // Define aggregate column
    var query = _db.selectOnly(_db.orders)..addColumns([totalAmountColumn]);

    Expression<bool> whereClause = const Constant(true);

    if (startDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isSmallerOrEqualValue(endDate);
    }

    query = query..where(whereClause);

    final result = await query.getSingleOrNull();
    return result?.read(totalAmountColumn) ??
        0.0; // Read using the defined aggregate column
  }

  /// Retrieves sales by inventory item, showing total quantity sold and total revenue for each item.
  Future<List<SalesByItem>> getSalesByItem({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Create properly typed aggregate columns
    final totalQuantitySoldColumn = _db.orderItems.quantity.sum();
    // Cast quantity to double before multiplication to ensure proper type
    final totalRevenueColumn =
        (_db.orderItems.quantity.cast<double>() * _db.orderItems.priceAtSale)
            .sum();

    var query = _db.selectOnly(_db.orderItems).join([
      innerJoin(
        _db.inventoryItems,
        _db.inventoryItems.id.equalsExp(_db.orderItems.itemId),
      ),
      innerJoin(_db.orders, _db.orders.id.equalsExp(_db.orderItems.orderId)),
    ]);

    query
      ..addColumns([
        _db.inventoryItems.id,
        _db.inventoryItems.name,
        totalQuantitySoldColumn,
        totalRevenueColumn,
      ])
      ..groupBy([_db.inventoryItems.id, _db.inventoryItems.name]);

    Expression<bool> whereClause = const Constant(true);

    if (startDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isSmallerOrEqualValue(endDate);
    }

    query = query..where(whereClause);

    final results = await query.get();

    return results.map((row) {
      return SalesByItem(
        itemId: row.read(_db.inventoryItems.id)!,
        itemName: row.read(_db.inventoryItems.name)!,
        totalQuantitySold: row.read(totalQuantitySoldColumn) ?? 0,
        totalRevenue: row.read(totalRevenueColumn) ?? 0.0,
      );
    }).toList();
  }

  /// Retrieves sales broken down by customer, showing total orders and total amount spent per customer.
  Future<List<SalesByCustomer>> getSalesByCustomer({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Create properly typed aggregate columns
    final totalOrdersColumn = _db.orders.id.count();
    final totalSpentColumn = _db.orders.totalAmount.sum();

    var query = _db.selectOnly(_db.orders).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.orders.customerId),
      ),
    ]);

    query
      ..addColumns([
        _db.customers.id,
        _db.customers.name,
        totalOrdersColumn,
        totalSpentColumn,
      ])
      ..groupBy([_db.customers.id, _db.customers.name]);

    Expression<bool> whereClause = const Constant(true);

    if (startDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      whereClause =
          whereClause & _db.orders.orderDate.isSmallerOrEqualValue(endDate);
    }

    query = query..where(whereClause);

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

  // --- Helper classes for joined queries and reports ---
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
  final double totalRevenue;

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
  final double totalSpent;

  SalesByCustomer({
    required this.customerId,
    required this.customerName,
    required this.totalOrders,
    required this.totalSpent,
  });
}
