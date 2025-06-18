// lib/features/order/presentation/order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/order_repository.dart';

// Provides the OrderNotifier, which manages the list of orders.
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderWithDetails>>>((ref) {
  return OrderNotifier(ref.read(orderRepositoryProvider));
});

// Provider to fetch a single order by ID.
final orderByIdProvider = FutureProvider.family<OrderWithDetails?, int>((ref, orderId) async {
  return ref.read(orderRepositoryProvider).getOrderById(orderId);
});

// --- NEW PROVIDERS FOR REPORTING ---

// Provider for total sales (can add date range later)
final totalSalesProvider = FutureProvider.autoDispose<double>((ref) {
  // For now, no date range. You can add parameters later.
  return ref.read(orderRepositoryProvider).getTotalSales();
});

// Provider for sales by item (can add date range later)
final salesByItemProvider = FutureProvider.autoDispose<List<SalesByItem>>((ref) {
  // For now, no date range. You can add parameters later.
  return ref.read(orderRepositoryProvider).getSalesByItem();
});

// Provider for sales by customer (can add date range later)
final salesByCustomerProvider = FutureProvider.autoDispose<List<SalesByCustomer>>((ref) {
  // For now, no date range. You can add parameters later.
  return ref.read(orderRepositoryProvider).getSalesByCustomer();
});


class OrderNotifier extends StateNotifier<AsyncValue<List<OrderWithDetails>>> {
  final OrderRepository _orderRepository;

  OrderNotifier(this._orderRepository) : super(const AsyncValue.loading()) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _orderRepository.getAllOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a new order and triggers a refresh of the order list.
  Future<bool> addOrder({
    required int customerId,
    required List<Map<String, dynamic>> items, // {itemId: int, quantity: int, priceAtSale: double}
  }) async {
    try {
      final success = await _orderRepository.createOrder(
        customerId: customerId,
        items: items,
      );
      if (success) {
        await _fetchOrders(); // Refresh list after successful addition
        // Invalidate report providers to refresh data
        // For simplicity, we're not invalidating here, but in a real app,
        // you'd invalidate affected report providers too.
      }
      return success;
    } catch (e) {
      print('Error adding order: $e');
      return false;
    }
  }

  /// Updates the status of an existing order and triggers a refresh.
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final success = await _orderRepository.updateOrderStatus(orderId, newStatus);
      if (success) {
        await _fetchOrders(); // Refresh list after successful update
        // Invalidate report providers to refresh data
      }
      return success;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // You can add more methods here for filtering, deleting, etc.
}

