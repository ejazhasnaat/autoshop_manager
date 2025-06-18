// lib/features/order/presentation/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // Add CommonAppBar import
import 'package:intl/intl.dart'; // For formatting

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDetailsAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Order Details',
        showBackButton: true, // <--- Show back button on detail screen
      ),
      body: orderDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
                // Order Summary
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        _buildDetailRow(context, 'Date:', DateFormat('yyyy-MM-dd HH:mm').format(order.orderDate)),
                        _buildDetailRow(context, 'Total Amount:', NumberFormat.currency(locale: 'en_US', symbol: '\$').format(order.totalAmount)),
                        _buildDetailRow(context, 'Status:', order.status),
                      ],
                    ),
                  ),
                ),

                // Customer Details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        _buildDetailRow(context, 'Name:', customer.name),
                        _buildDetailRow(context, 'Phone:', customer.phoneNumber),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          _buildDetailRow(context, 'Email:', customer.email!),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          _buildDetailRow(context, 'Address:', customer.address!),
                      ],
                    ),
                  ),
                ),

                // Order Items
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        if (items.isEmpty)
                          const Text('No items in this order.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final orderItem = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${orderItem.inventoryItem.name} (x${orderItem.orderItem.quantity})',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text(
                                            'Part #: ${orderItem.inventoryItem.partNumber}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(locale: 'en_US', symbol: '\$').format(orderItem.orderItem.priceAtSale * orderItem.orderItem.quantity),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Optional: Button to change order status
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Example: show a dialog to change status
                      _showStatusChangeDialog(context, ref, order.id, order.status);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Order Status'),
                  ),
                ),
              ],
            ),
          );
        },
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
            width: 120,
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

  void _showStatusChangeDialog(BuildContext context, WidgetRef ref, int orderId, String currentStatus) {
    String? selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Order Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'New Status',
                  border: OutlineInputBorder(),
                ),
                items: <String>['Pending', 'Processing', 'Completed', 'Cancelled']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null || selectedStatus == currentStatus
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      await ref.read(orderNotifierProvider.notifier).updateOrderStatus(orderId, selectedStatus!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order status updated.')),
                      );
                    },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

