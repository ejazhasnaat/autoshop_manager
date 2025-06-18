// lib/features/inventory/presentation/screens/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart'; // <--- Ensure this is imported
import 'package:autoshop_manager/widgets/common_app_bar.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // <--- FIX: Watch the inventoryListProvider (which exposes the state of the notifier)
    final inventoryItemsAsyncValue = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Inventory'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/inventory/add'),
        child: const Icon(Icons.add),
      ),
      body: inventoryItemsAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No inventory items found. Add a new item to get started!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock = item.quantity < 5; // Example low stock threshold
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLowStock ? Colors.orange.shade700 : null,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Part Number: ${item.partNumber}'),
                      if (item.supplier != null && item.supplier!.isNotEmpty)
                        Text('Supplier: ${item.supplier}'),
                      Text('Stock: ${item.quantity} ${isLowStock ? '(Low Stock!)' : ''}'),
                      Text('Cost: \$${item.costPrice.toStringAsFixed(2)} | Sale: \$${item.salePrice.toStringAsFixed(2)}'),
                      if (item.stockLocation != null && item.stockLocation!.isNotEmpty)
                        Text('Location: ${item.stockLocation}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          context.go('/inventory/edit/${item.id}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete item "${item.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(inventoryNotifierProvider.notifier).deleteInventoryItem(item.id); // <--- FIX: Correct method call
                                    Navigator.of(ctx).pop(); // Dismiss dialog
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

