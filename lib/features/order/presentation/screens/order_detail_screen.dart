// lib/features/order/presentation/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart'; // <--- NEW IMPORT

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDetailsAsync = ref.watch(orderByIdProvider(orderId));
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider); // <--- WATCH CURRENCY

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Order Details',
        showBackButton: true,
        customActions: [
          orderDetailsAsync.when(
            data: (orderWithDetails) {
              if (orderWithDetails != null) {
                return IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    // TODO: Implement print functionality (e.g., generate PDF)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Print functionality coming soon!')),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const CircularProgressIndicator.adaptive(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orderDetailsAsync.when(
        data: (orderWithDetails) {
          if (orderWithDetails == null) {
            return const Center(child: Text('Order not found.'));
          }

          final order = orderWithDetails.order;
          final customer = orderWithDetails.customer;
          final items = orderWithDetails.items;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Order ID', '#${order.id}'),
                        _buildDetailRow(context, 'Date', order.orderDate.toLocal().toString().split(' ')[0]),
                        _buildDetailRow(context, 'Status', order.status),
                        _buildDetailRow(context, 'Total Amount', '$currentCurrencySymbol${order.totalAmount.toStringAsFixed(2)}'), // <--- USE CURRENCY
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Name', customer.name),
                        _buildDetailRow(context, 'Phone', customer.phoneNumber),
                        if (customer.whatsappNumber != null && customer.whatsappNumber!.isNotEmpty)
                          _buildDetailRow(context, 'WhatsApp', customer.whatsappNumber!),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          _buildDetailRow(context, 'Email', customer.email!),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          _buildDetailRow(context, 'Address', customer.address!),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items in Order',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No items in this order.'),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: ListTile(
                                  title: Text(item.inventoryItem.name, style: Theme.of(context).textTheme.titleSmall),
                                  subtitle: Text(
                                    '${item.orderItem.quantity} x $currentCurrencySymbol${item.orderItem.priceAtSale.toStringAsFixed(2)} = $currentCurrencySymbol${(item.orderItem.quantity * item.orderItem.priceAtSale).toStringAsFixed(2)}', // <--- USE CURRENCY
                                  ),
                                  leading: CircleAvatar(
                                    child: Text(item.orderItem.quantity.toString()),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for labels
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

