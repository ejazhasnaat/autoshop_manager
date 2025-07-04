// lib/features/reports/presentation/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value, String symbol) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final totalSalesAsync = ref.watch(totalSalesProvider);
    final salesByItemAsync = ref.watch(salesByItemReportProvider);
    final salesByCustomerAsync = ref.watch(salesByCustomerReportProvider);
    final currencySymbol = ref.watch(currentCurrencySymbolProvider);
    
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Sales Reports', showBackButton: true),
      body: Column(
        children: [
          // --- Total Sales Card remains at the top ---
          totalSalesAsync.when(
            data: (totalSales) => Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Sales', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(totalSales, currencySymbol),
                      style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Could not load total sales.', style: TextStyle(color: colorScheme.error)),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
          ),
          
          // --- FIX: TabBar is now part of the screen body ---
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'By Item'),
              Tab(text: 'By Customer'),
            ],
          ),

          // --- FIX: TabBarView is now in an Expanded widget ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sales by Item Report Tab
                salesByItemAsync.when(
                  data: (reportData) {
                    if (reportData.isEmpty) {
                      return const Center(child: Text('No sales data found for items.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reportData.length,
                      itemBuilder: (context, index) {
                        final item = reportData[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(item.itemName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('Quantity Sold: ${item.totalQuantitySold}'),
                            trailing: Text(
                              _formatCurrency(item.totalRevenue, currencySymbol),
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.secondary),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                // Sales by Customer Report Tab
                salesByCustomerAsync.when(
                  data: (reportData) {
                    if (reportData.isEmpty) {
                      return const Center(child: Text('No sales data found for customers.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reportData.length,
                      itemBuilder: (context, index) {
                        final customer = reportData[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(customer.customerName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('Total Orders: ${customer.totalOrders}'),
                             trailing: Text(
                              _formatCurrency(customer.totalSpent, currencySymbol),
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.secondary),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
