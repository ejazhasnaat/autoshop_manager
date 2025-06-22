// lib/features/order/presentation/order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/order_repository.dart';

// StreamProvider for a single order with details
final orderByIdProvider = StreamProvider.family<OrderWithDetails?, int>((ref, orderId) {
  return Stream.fromFuture(ref.read(orderRepositoryProvider).getOrderWithDetails(orderId));
});

// StreamProvider for all orders with details
final ordersListProvider = StreamProvider<List<OrderWithDetails>>((ref) {
  return Stream.fromFuture(ref.read(orderRepositoryProvider).getAllOrdersWithDetails());
});

// Provider for sales by item report
final salesByItemReportProvider = FutureProvider<List<SalesByItem>>((ref) async {
  return ref.read(orderRepositoryProvider).getSalesByItemReport();
});

// Provider for sales by customer report
final salesByCustomerReportProvider = FutureProvider<List<SalesByCustomer>>((ref) async {
  return ref.read(orderRepositoryProvider).getSalesByCustomerReport();
});

// --- FIX: Added the missing provider for total sales ---
final totalSalesProvider = FutureProvider<double>((ref) async {
  // This follows the existing pattern of calling a method on the repository.
  return ref.read(orderRepositoryProvider).getTotalSales();
});


// StateNotifierProvider for managing orders
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderWithDetails>>>((ref) {
  return OrderNotifier(ref.read(orderRepositoryProvider), ref);
});

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderWithDetails>>> {
  final OrderRepository _repository;
  final Ref _ref; // Keep ref to invalidate or re-fetch

  OrderNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _repository.getAllOrdersWithDetails(); // Correct method call
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createOrder({
    required int customerId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final success = await _repository.createOrder(customerId: customerId, items: items);
      if (success) {
        _fetchOrders(); // Re-fetch all orders after creation
      }
      return success;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(int orderId) async {
    try {
      final success = await _repository.deleteOrder(orderId);
      if (success) {
        _fetchOrders(); // Re-fetch all orders after deletion
      }
      return success;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final success = await _repository.updateOrderStatus(orderId, newStatus);
      if (success) {
        _fetchOrders(); // Re-fetch all orders after status update
      }
      return success;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
}

