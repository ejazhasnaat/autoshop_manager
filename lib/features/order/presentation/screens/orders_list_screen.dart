// lib/features/order/presentation/screens/orders_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // <--- NEW IMPORT
import 'package:intl/intl.dart'; // For date and currency formatting

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Orders'), // <--- Using CommonAppBar
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/orders/add'),
        child: const Icon(Icons.add),
      ),
      body: ordersAsyncValue.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No orders found. Create a new order to get started!',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderWithDetails = orders[index];
              final order = orderWithDetails.order;
              final customer = orderWithDetails.customer;

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  title: Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Customer: ${customer.name}'),
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(order.orderDate)}',
                      ),
                      Text(
                        'Total: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(order.totalAmount)}',
                      ),
                      Text('Status: ${order.status}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.visibility,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          context.go(
                            '/orders/${order.id}',
                          ); // View order details
                        },
                      ),
                      // Example of a status update button (you might want a more elaborate UI)
                      // IconButton(
                      //   icon: Icon(Icons.check_circle_outline, color: Colors.green),
                      //   onPressed: () {
                      //     // ref.read(orderNotifierProvider.notifier).updateOrderStatus(order.id, 'Completed');
                      //   },
                      // ),
                    ],
                  ),
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
