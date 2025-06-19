// lib/features/order/presentation/screens/add_edit_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart'; // Import CustomerWithVehicles


class AddEditOrderScreen extends ConsumerStatefulWidget {
  const AddEditOrderScreen({super.key});

  @override
  ConsumerState<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends ConsumerState<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer; // Now directly holds Customer
  final List<OrderItemEntry> _orderItemEntries = [];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final inventoryItemsAsync = ref.watch(inventoryNotifierProvider);
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    double totalAmount = _orderItemEntries.fold(0.0, (sum, item) => sum + (item.quantity * item.priceAtSale));

    return Scaffold(
      appBar: const CommonAppBar(title: 'Create New Order', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
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
                              'Order Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            customersAsync.when(
                              data: (customersWithVehicles) { // Data is List<CustomerWithVehicles>
                                return DropdownButtonFormField<Customer>( // Expects Customer
                                  decoration: const InputDecoration(labelText: 'Select Customer*'),
                                  value: _selectedCustomer,
                                  items: customersWithVehicles.map((customerWithVehicles) {
                                    return DropdownMenuItem<Customer>( // Explicitly type DropdownMenuItem
                                      value: customerWithVehicles.customer, // Use customer property
                                      child: Text('${customerWithVehicles.customer.name} (${customerWithVehicles.customer.phoneNumber})'), // Access customer properties
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedCustomer = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a customer';
                                    }
                                    return null;
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                              error: (err, stack) => Text('Error loading customers: $err'),
                            ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order Items',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 30),
                                  onPressed: () => _showAddItemDialog(inventoryItemsAsync, currentCurrencySymbol),
                                  tooltip: 'Add Order Item',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _orderItemEntries.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No items added to this order. Please add at least one.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _orderItemEntries.length,
                                    itemBuilder: (context, index) {
                                      final entry = _orderItemEntries[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        child: ListTile(
                                          title: Text(entry.itemName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${entry.quantity} x $currentCurrencySymbol${entry.priceAtSale.toStringAsFixed(2)} = $currentCurrencySymbol${(entry.quantity * entry.priceAtSale).toStringAsFixed(2)}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _orderItemEntries.removeAt(index);
                                              });
                                            },
                                            tooltip: 'Remove Item',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total Amount: $currentCurrencySymbol${totalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _selectedCustomer == null || _orderItemEntries.isEmpty
                            ? null
                            : _createOrder,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : const Text('Create Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Method to show dialog for adding order item
  void _showAddItemDialog(AsyncValue<List<InventoryItem>> inventoryItemsAsync, String currencySymbol) {
    InventoryItem? selectedInventoryItem;
    final quantityController = TextEditingController(text: '1');
    final priceAtSaleController = TextEditingController();
    final itemFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Item to Order'),
          content: SingleChildScrollView(
            child: Form(
              key: itemFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  inventoryItemsAsync.when(
                    data: (items) {
                      return DropdownButtonFormField<InventoryItem>(
                        decoration: const InputDecoration(labelText: 'Select Item*'),
                        value: selectedInventoryItem,
                        items: items.map((item) {
                          return DropdownMenuItem<InventoryItem>( // Explicitly cast
                            value: item,
                            child: Text('${item.name} (${item.partNumber}) - Qty: ${item.quantity}'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedInventoryItem = newValue;
                            if (newValue != null) {
                              priceAtSaleController.text = newValue.salePrice.toStringAsFixed(2);
                            } else {
                              priceAtSaleController.clear();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an item';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator.adaptive(),
                    error: (err, stack) => Text('Error loading inventory: $err'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity*'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final int? qty = int.tryParse(value ?? '');
                      if (qty == null || qty <= 0) {
                        return 'Enter valid quantity';
                      }
                      if (selectedInventoryItem != null && qty > selectedInventoryItem!.quantity) {
                        return 'Not enough stock (Available: ${selectedInventoryItem!.quantity})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceAtSaleController,
                    decoration: InputDecoration(labelText: 'Price at Sale*', prefixText: '$currencySymbol '),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (itemFormKey.currentState?.validate() ?? false) {
                  setState(() {
                    _orderItemEntries.add(
                      OrderItemEntry(
                        itemId: selectedInventoryItem!.id!,
                        itemName: selectedInventoryItem!.name,
                        quantity: int.parse(quantityController.text),
                        priceAtSale: double.parse(priceAtSaleController.text),
                      ),
                    );
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrder() async {
    if (_formKey.currentState?.validate() ?? false && _orderItemEntries.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final orderNotifier = ref.read(orderNotifierProvider.notifier);
      final success = await orderNotifier.createOrder(
        customerId: _selectedCustomer!.id!,
        items: _orderItemEntries.map((e) => {
          'itemId': e.itemId,
          'quantity': e.quantity,
          'priceAtSale': e.priceAtSale,
        }).toList(),
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create order.')),
        );
      }
    }
  }
}

// Custom class to hold order item details for the UI draft
class OrderItemEntry {
  final int itemId;
  final String itemName;
  final int quantity;
  final double priceAtSale;

  OrderItemEntry({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.priceAtSale,
  });
}

