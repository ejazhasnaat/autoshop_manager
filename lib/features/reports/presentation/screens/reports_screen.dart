// lib/features/reports/presentation/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';


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

  @override
  Widget build(BuildContext context) {
    // Correctly watch the providers here
    final salesByItemAsync = ref.watch(salesByItemReportProvider);
    final salesByCustomerAsync = ref.watch(salesByCustomerReportProvider);
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Reports',
        showBackButton: true,
        // The 'bottom' property of AppBar expects a PreferredSizeWidget
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight), // Standard height for TabBar
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Sales by Item', icon: Icon(Icons.inventory)),
              Tab(text: 'Sales by Customer', icon: Icon(Icons.people)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sales by Item Report Tab
          salesByItemAsync.when(
            data: (reportData) {
              if (reportData.isEmpty) {
                return const Center(child: Text('No sales data by item.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: reportData.length,
                itemBuilder: (context, index) {
                  final item = reportData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(item.itemName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Quantity Sold: ${item.totalQuantitySold} | Revenue: $currentCurrencySymbol${item.totalRevenue.toStringAsFixed(2)}'),
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
                return const Center(child: Text('No sales data by customer.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: reportData.length,
                itemBuilder: (context, index) {
                  final customer = reportData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(customer.customerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Total Orders: ${customer.totalOrders} | Total Spent: $currentCurrencySymbol${customer.totalSpent.toStringAsFixed(2)}'),
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
    );
  }
}

