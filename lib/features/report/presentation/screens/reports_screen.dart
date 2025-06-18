// lib/features/report/presentation/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart'; // For reporting providers
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // <--- NEW IMPORT
import 'package:intl/intl.dart'; // For currency formatting

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSalesAsync = ref.watch(totalSalesProvider);
    final salesByItemAsync = ref.watch(salesByItemProvider);
    final salesByCustomerAsync = ref.watch(salesByCustomerProvider);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Sales Reports',
      ), // <--- Using CommonAppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          16.0,
        ), // <--- FIX: Changed to EdgeInsets.all
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Sales Card
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  16.0,
                ), // <--- FIX: Changed to EdgeInsets.all
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sales',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    totalSalesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text(
                        'Error: $err',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      data: (totalSales) => Text(
                        NumberFormat.currency(
                          locale: 'en_US',
                          symbol: '\$',
                        ).format(totalSales),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sales By Item Report
            Text(
              'Sales By Item',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            salesByItemAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (salesItems) {
                if (salesItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No item sales data available.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: salesItems.length,
                  itemBuilder: (context, index) {
                    final item = salesItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 4.0,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Quantity Sold: ${item.totalQuantitySold}',
                                ),
                                Text(
                                  'Revenue: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(item.totalRevenue)}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Sales By Customer Report
            Text(
              'Sales By Customer',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            salesByCustomerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (salesCustomers) {
                if (salesCustomers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No customer sales data available.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: salesCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = salesCustomers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 4.0,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.customerName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Orders: ${customer.totalOrders}'),
                                Text(
                                  'Total Spent: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(customer.totalSpent)}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
