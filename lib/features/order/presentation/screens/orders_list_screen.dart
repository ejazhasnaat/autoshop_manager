// lib/features/order/presentation/screens/orders_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';


class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(ordersListProvider); // <--- FIX: Use correct provider name
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Orders'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/orders/add'),
        tooltip: 'Create New Order',
        child: const Icon(Icons.add),
      ),
      body: ordersAsyncValue.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders found. Create a new order to get started!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].order;
              final customer = orders[index].customer;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    'Order #${order.id} - ${customer.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Date: ${order.orderDate.toLocal().toString().split(' ')[0]}'),
                      Text('Total: $currentCurrencySymbol${order.totalAmount.toStringAsFixed(2)}'),
                      Text('Status: ${order.status}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: () {
                          context.go('/orders/${order.id}');
                        },
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete order #${order.id}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(orderNotifierProvider.notifier).deleteOrder(order.id!);
                                    Navigator.of(ctx).pop();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete Order',
                      ),
                    ],
                  ),
                  onTap: () {
                    context.go('/orders/${order.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

