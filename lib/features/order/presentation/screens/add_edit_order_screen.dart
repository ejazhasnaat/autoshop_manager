// lib/features/order/presentation/screens/add_edit_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart'; // For customerListProvider
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart'; // For inventoryNotifierProvider
import 'package:autoshop_manager/features/order/presentation/order_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // Add CommonAppBar import
import 'package:uuid/uuid.dart'; // For unique keys for added items
import 'package:autoshop_manager/data/repositories/customer_repository.dart'; // <--- NEW IMPORT for CustomerWithVehicles

// Helper class to manage items temporarily added to the order
class OrderItemDraft {
  final String id; // Unique ID for Widget keys
  final InventoryItem item;
  int quantity;
  double priceAtSale; // Price for this specific order item

  OrderItemDraft({
    String? id,
    required this.item,
    required this.quantity,
    required this.priceAtSale,
  }) : id = id ?? const Uuid().v4();

  // For updating quantity
  OrderItemDraft copyWith({
    int? quantity,
  }) {
    return OrderItemDraft(
      id: id,
      item: item,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale,
    );
  }
}


final _selectedCustomerProvider = StateProvider<CustomerWithVehicles?>((ref) => null);
final _orderItemsDraftProvider = StateNotifierProvider<OrderItemsDraftNotifier, List<OrderItemDraft>>((ref) => OrderItemsDraftNotifier());

class OrderItemsDraftNotifier extends StateNotifier<List<OrderItemDraft>> {
  OrderItemsDraftNotifier() : super([]);

  void addItem(InventoryItem item, int quantity, double priceAtSale) {
    // Check if item already exists in draft, if so, update quantity
    final existingIndex = state.indexWhere((element) => element.item.id == item.id);
    if (existingIndex != -1) {
      final updatedItem = state[existingIndex].copyWith(quantity: state[existingIndex].quantity + quantity);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) updatedItem else state[i],
      ];
    } else {
      state = [...state, OrderItemDraft(item: item, quantity: quantity, priceAtSale: priceAtSale)];
    }
  }

  void updateItemQuantity(String draftItemId, int newQuantity) {
    state = [
      for (final draftItem in state)
        if (draftItem.id == draftItemId)
          draftItem.copyWith(quantity: newQuantity)
        else
          draftItem,
    ];
  }

  void removeItem(String draftItemId) {
    state = state.where((item) => item.id != draftItemId).toList();
  }

  void clearAllItems() {
    state = [];
  }

  double calculateTotal() {
    return state.fold(0.0, (sum, item) => sum + (item.quantity * item.priceAtSale));
  }
}


class AddEditOrderScreen extends ConsumerStatefulWidget {
  const AddEditOrderScreen({super.key});

  @override
  ConsumerState<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends ConsumerState<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final selectedCustomer = ref.watch(_selectedCustomerProvider);
    final orderItemsDraft = ref.watch(_orderItemsDraftProvider);
    final totalAmount = ref.watch(_orderItemsDraftProvider.notifier).calculateTotal();

    List<Step> steps = [
      Step(
        title: const Text('Select Customer'),
        content: _buildCustomerSelectionStep(context, ref),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Add Items'),
        content: _buildAddItemsStep(context, ref, orderItemsDraft),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text('Confirm Order (\$${totalAmount.toStringAsFixed(2)})'),
        content: _buildConfirmOrderStep(context, ref, selectedCustomer, orderItemsDraft, totalAmount),
        isActive: _currentStep >= 2,
        state: _currentStep == 2 ? StepState.editing : StepState.indexed,
      ),
    ];

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Create New Order',
        showBackButton: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep == 0) {
            if (selectedCustomer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a customer.')),
              );
              return;
            }
          } else if (_currentStep == 1) {
            if (orderItemsDraft.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one item.')),
              );
              return;
            }
          } else if (_currentStep == 2) {
            // Final step: Save order
            await _saveOrder();
            return; // Don't increment step after saving
          }
          setState(() {
            _currentStep < steps.length - 1 ? _currentStep += 1 : null;
          });
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          } else {
            context.pop(); // Go back if on first step
          }
        },
        steps: steps,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                        : Text(_currentStep == steps.length - 1 ? 'Place Order' : 'Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerSelectionStep(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final selectedCustomer = ref.watch(_selectedCustomerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a customer for this order:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading customers: $err'),
          data: (customersWithVehicles) {
            return DropdownButtonFormField<CustomerWithVehicles>(
              decoration: const InputDecoration(
                labelText: 'Select Customer',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: selectedCustomer,
              hint: const Text('Select a customer'),
              isExpanded: true,
              onChanged: (CustomerWithVehicles? newValue) {
                ref.read(_selectedCustomerProvider.notifier).state = newValue;
              },
              items: customersWithVehicles.map<DropdownMenuItem<CustomerWithVehicles>>((CustomerWithVehicles customerWithVehiclesItem) {
                return DropdownMenuItem<CustomerWithVehicles>(
                  value: customerWithVehiclesItem,
                  child: Text('${customerWithVehiclesItem.customer.name} (${customerWithVehiclesItem.customer.phoneNumber})'),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddItemsStep(BuildContext context, WidgetRef ref, List<OrderItemDraft> orderItemsDraft) {
    final inventoryItemsAsync = ref.watch(inventoryNotifierProvider);
    final orderItemsNotifier = ref.read(_orderItemsDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select items and quantities:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        inventoryItemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading inventory: $err'),
          data: (inventoryItems) {
            return Column(
              children: [
                // Display currently added items
                if (orderItemsDraft.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items in Order:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderItemsDraft.length,
                        itemBuilder: (context, index) {
                          final itemDraft = orderItemsDraft[index];
                          return Card(
                            key: ValueKey(itemDraft.id), // Important for ListView item identity
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemDraft.item.name,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text('Part: ${itemDraft.item.partNumber} | Price: \$${itemDraft.priceAtSale.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: itemDraft.quantity.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      validator: (value) {
                                        final qty = int.tryParse(value ?? '');
                                        if (qty == null || qty <= 0) return ''; // Minimal validation, just for visual
                                        if (qty > itemDraft.item.quantity) return 'Over stock!';
                                        return null;
                                      },
                                      onChanged: (value) {
                                        final newQty = int.tryParse(value) ?? 0;
                                        if (newQty > 0) {
                                           orderItemsNotifier.updateItemQuantity(itemDraft.id, newQty);
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      orderItemsNotifier.removeItem(itemDraft.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Text(
                  'Add New Item to Order:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Inventory search and add
                DropdownButtonFormField<InventoryItem>(
                  decoration: const InputDecoration(
                    labelText: 'Select Inventory Item',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: const Text('Search or select an item'),
                  isExpanded: true,
                  onChanged: (InventoryItem? selectedItem) {
                    if (selectedItem != null) {
                      _showAddItemDialog(context, ref, selectedItem);
                    }
                  },
                  items: inventoryItems.map<DropdownMenuItem<InventoryItem>>((InventoryItem item) {
                    return DropdownMenuItem<InventoryItem>(
                      value: item,
                      child: Text('${item.name} (${item.partNumber}) - Stock: ${item.quantity}'),
                    );
                  }).toList(),
                  // You might want an autocomplete search here instead of a simple dropdown for many items
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, InventoryItem item) {
    final quantityController = TextEditingController(text: '1');
    final orderItemsNotifier = ref.read(_orderItemsDraftProvider.notifier);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add ${item.name} to Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available Stock: ${item.quantity}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty <= 0) {
                    return 'Enter a valid quantity';
                  }
                  if (qty > item.quantity) {
                    return 'Quantity exceeds available stock!';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(quantityController.text);
                if (qty != null && qty > 0 && qty <= item.quantity) {
                  orderItemsNotifier.addItem(item, qty, item.salePrice);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid quantity or insufficient stock for ${item.name}')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmOrderStep(BuildContext context, WidgetRef ref, CustomerWithVehicles? customerWithVehicles, List<OrderItemDraft> items, double total) {
    final customer = customerWithVehicles?.customer; // Get actual Customer object
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Order Details:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        if (customer != null)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('Name: ${customer.name}'),
                  Text('Phone: ${customer.phoneNumber}'),
                  if (customer.email != null) Text('Email: ${customer.email}'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Items:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.item.name} (x${item.quantity})')),
                    Text('\$${(item.quantity * item.priceAtSale).toStringAsFixed(2)}'),
                  ],
                ),
              );
            },
          ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _saveOrder() async {
    final selectedCustomerWithVehicles = ref.read(_selectedCustomerProvider);
    final orderItemsDraft = ref.read(_orderItemsDraftProvider);
    final orderNotifier = ref.read(orderNotifierProvider.notifier);

    if (selectedCustomerWithVehicles == null || orderItemsDraft.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps (select customer and add items).')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final List<Map<String, dynamic>> itemsForRepo = orderItemsDraft.map((itemDraft) {
      return {
        'itemId': itemDraft.item.id,
        'quantity': itemDraft.quantity,
        'priceAtSale': itemDraft.priceAtSale,
      };
    }).toList();

    final success = await orderNotifier.addOrder(
      customerId: selectedCustomerWithVehicles.customer.id!, // Access customer.id
      items: itemsForRepo,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      // Clear draft items after successful order
      ref.read(_orderItemsDraftProvider.notifier).clearAllItems();
      ref.read(_selectedCustomerProvider.notifier).state = null; // Clear selected customer
      context.go('/orders'); // Navigate back to orders list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Check stock or try again.')),
      );
    }
  }
}

