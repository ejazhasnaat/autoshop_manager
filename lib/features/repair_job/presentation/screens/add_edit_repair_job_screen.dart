// lib/features/repair_job/presentation/screens/add_edit_repair_job_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/features/service/presentation/service_providers.dart';
import 'package:autoshop_manager/features/repair_job/presentation/notifiers/add_edit_repair_job_notifier.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class AddEditRepairJobScreen extends ConsumerWidget {
  final int? repairJobId;

  final _othersListKey = GlobalKey<_EditableItemsListState>();
  final _servicesListKey = GlobalKey<_EditableItemsListState>();
  final _partsListKey = GlobalKey<_EditableItemsListState>();

  AddEditRepairJobScreen({super.key, this.repairJobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final othersKey = _othersListKey;
    final servicesKey = _servicesListKey;
    final partsKey = _partsListKey;

    final provider = addEditRepairJobNotifierProvider(repairJobId);
    final state = ref.watch(provider);
    final isNewJob = repairJobId == null;
    final preferencesAsync = ref.watch(userPreferencesStreamProvider);

    void _saveAllEdits() {
      othersKey.currentState?._saveAndExitEditMode();
      servicesKey.currentState?._saveAndExitEditMode();
      partsKey.currentState?._saveAndExitEditMode();
      FocusScope.of(context).unfocus();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Save and Close',
          onPressed: () async {
            _saveAllEdits();
            await Future.delayed(const Duration(milliseconds: 50));

            if (ref.read(provider).selectedVehicle != null) {
              await ref.read(provider.notifier).saveJob();
            }
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        title: Text(isNewJob ? 'New Repair Job' : 'Edit Repair Job'),
        actions: [
          if (!isNewJob && state.status != 'Completed')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete & Bill'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          _saveAllEdits();
                          await Future.delayed(const Duration(milliseconds: 50));
                          try {
                            final completedId = await ref
                                .read(provider.notifier)
                                .completeAndBillJob();
                            if (!context.mounted) return;
                            
                            context.go('/repairs/edit/$completedId/receipt');

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Job Completed!'),
                                  backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error),
                            );
                          }
                        },
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: _saveAllEdits,
        child: preferencesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) =>
                Center(child: Text("Error loading settings: $err")),
            data: (prefs) {
              final currencySymbol = prefs.defaultCurrency;

              return state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCustomerAndVehicleSection(context, ref),
                              const SizedBox(height: 16),
                              _buildDetailsCard(context, ref),
                              const SizedBox(height: 24),
                              _buildItemsSection(context, ref, 'Services', servicesKey, currencySymbol),
                              const SizedBox(height: 24),
                              _buildItemsSection(context, ref, 'Parts', partsKey, currencySymbol),
                              const SizedBox(height: 24),
                              _buildItemsSection(context, ref, 'Others', othersKey, currencySymbol),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    'Grand Total: ${NumberFormat.currency(symbol: '$currencySymbol ').format(state.totalCost)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                        if (state.isSaving)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
            }),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, WidgetRef ref, String title, Key key, String currencySymbol) {
    final state = ref.watch(addEditRepairJobNotifierProvider(repairJobId));
    final bool isService = title == 'Services';
    final bool isPart = title == 'Parts';
    final bool isOther = title == 'Others';

    final items = state.items.where((i) {
      if(isService) return i.itemType == 'Service';
      if(isPart) return i.itemType == 'InventoryItem';
      if(isOther) return i.itemType == 'Other';
      return false;
    }).toList();
    
    final double subTotal;
    if(isService) subTotal = state.servicesTotalCost;
    else if(isPart) subTotal = state.partsTotalCost;
    else subTotal = state.othersTotalCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '(tap an item to edit)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(isService ? 'Add Service' : (isPart ? 'Add Part' : 'Add Other')),
              onPressed: state.selectedVehicle == null || state.status == 'Completed'
                  ? null
                  : () {
                      (key as GlobalKey<_EditableItemsListState>).currentState?._saveAndExitEditMode();
                      
                      if (isService) {
                        _showAddServiceDialog(context, ref, currencySymbol);
                      } else if (isPart) {
                        _showAddPartDialog(context, ref);
                      } else {
                        _showAddOtherDialog(context, ref);
                      }
                    },
            ),
          ],
        ),
        const Divider(),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('No items added yet.')),
          )
        else
          _EditableItemsList(
            key: key,
            items: items,
            jobId: repairJobId,
            currencySymbol: currencySymbol,
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Sub-Total: ${NumberFormat.currency(symbol: '$currencySymbol ').format(subTotal)}',
            style: Theme.of(context).textTheme.titleMedium
          ),
        )
      ],
    );
  }

  void _showAddOtherDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Other Item or Charge'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: descriptionController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a description'
                        : null,
                  ),
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                     validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == 0)
                        ? 'Enter a valid quantity'
                        : null,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null)
                        ? 'Enter a valid price'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref
                        .read(addEditRepairJobNotifierProvider(repairJobId)
                            .notifier)
                        .addOtherItem(
                          description: descriptionController.text,
                          quantity: int.parse(qtyController.text),
                          price: double.parse(priceController.text),
                        );
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
  }

  void _showDuplicateItemDialog({
    required BuildContext context,
    required String itemName,
    required VoidCallback onIncrement,
    required VoidCallback onAddNew,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duplicate Item'),
        content: Text('"$itemName" is already in this job. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAddNew();
            },
            child: const Text('Add as New'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onIncrement();
            },
            child: const Text('Increase Quantity'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, WidgetRef ref, String currencySymbol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final servicesAsync = ref.watch(serviceListProvider);
            final notifier = ref.read(addEditRepairJobNotifierProvider(repairJobId).notifier);
            final numberFormat = NumberFormat.currency(symbol: '$currencySymbol ');
            
            return AlertDialog(
              title: const Text('Add Service'),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Search by service or category...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (value) {
                          ref.read(serviceSearchQueryProvider.notifier).state = value;
                        },
                      ),
                    ),
                    Expanded(
                      child: servicesAsync.when(
                        data: (services) {
                          if (services.isEmpty) {
                            return const Center(child: Text('No services found.'));
                          }
                          
                          final groupedServices = groupBy(services, (Service s) => s.category);
                          
                          return ListView.builder(
                            itemCount: groupedServices.keys.length,
                            itemBuilder: (context, index) {
                              final category = groupedServices.keys.elementAt(index);
                              final serviceItems = groupedServices[category]!;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ExpansionTile(
                                  title: Text(
                                    "$category (${serviceItems.length})",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  children: serviceItems.map((service) {
                                    return ListTile(
                                      title: Text(service.name),
                                      trailing: Text(numberFormat.format(service.price)),
                                      onTap: () {
                                        final jobItems = ref.read(addEditRepairJobNotifierProvider(repairJobId)).items;
                                        final existingItem = jobItems.firstWhereOrNull((item) => item.itemType == 'Service' && item.linkedItemId == service.id);

                                        if (existingItem != null) {
                                          _showDuplicateItemDialog(
                                            context: context,
                                            itemName: service.name,
                                            onIncrement: () {
                                              notifier.incrementItemQuantity(existingItem);
                                              Navigator.of(context).pop();
                                            },
                                            onAddNew: () {
                                              notifier.addServiceItem(service);
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        } else {
                                          notifier.addServiceItem(service);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Error: $e'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'))
              ],
            );
          },
        );
      },
    );
  }
  
  void _showAddPartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (consumerContext, ref, _) {
          final inventoryAsync = ref.watch(inventoryNotifierProvider);
          final notifier = ref.read(addEditRepairJobNotifierProvider(repairJobId).notifier);

          void attemptToAddItem(InventoryItem item, int quantity) {
            final success = notifier.addInventoryItem(item, quantity);
            
            if (consumerContext.mounted) {
              Navigator.of(consumerContext).pop();
            }

            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to add part: Not enough items in stock.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text('Add Part from Inventory'),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search by Name, Number, or Make',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (value) {
                        ref.read(inventoryNotifierProvider.notifier).applyFiltersAndSort(searchTerm: value);
                      },
                    ),
                  ),
                  Expanded(
                    child: inventoryAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(child: Text('No parts found.'));
                        }
                        
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('In Stock: ${item.quantity}'),
                              onTap: () {
                                final jobItems = ref.read(addEditRepairJobNotifierProvider(repairJobId)).items;
                                final existingItem = jobItems.firstWhereOrNull((jobItem) => jobItem.itemType == 'InventoryItem' && jobItem.linkedItemId == item.id);

                                if (existingItem != null) {
                                  _showDuplicateItemDialog(
                                    context: consumerContext,
                                    itemName: item.name,
                                    onIncrement: () {
                                      notifier.incrementItemQuantity(existingItem);
                                      Navigator.of(consumerContext).pop();
                                    },
                                    onAddNew: () {
                                      attemptToAddItem(item, 1);
                                    },
                                  );
                                } else {
                                  attemptToAddItem(item, 1);
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => const Text('Could not load inventory.'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(consumerContext).pop(), child: const Text('Cancel'))
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerAndVehicleSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addEditRepairJobNotifierProvider(repairJobId));
    final notifier = ref.read(addEditRepairJobNotifierProvider(repairJobId).notifier);
    final customersAsync = ref.watch(customerListProvider);
    final vehicles = state.selectedCustomerWithVehicles?.vehicles ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: customersAsync.when(
                    data: (customers) => DropdownButtonFormField<CustomerWithVehicles>(
                      value: state.selectedCustomerWithVehicles,
                      hint: const Text('Select a Customer'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.customer.name)))
                          .toList(),
                      onChanged: state.status == 'Completed' ? null : (customer) {
                        if (customer != null) notifier.setCustomer(customer);
                      },
                    ),
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                ),
              ],
            ),
            
            if (state.selectedCustomerWithVehicles != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text('Vehicle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Vehicle>(
                      value: state.selectedVehicle,
                      hint: const Text('Select a Vehicle'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                  '${v.make} ${v.model} - ${v.registrationNumber}')))
                          .toList(),
                      onChanged:  state.status == 'Completed' ? null : (vehicle) {
                        if (vehicle != null) notifier.setVehicle(vehicle);
                      },
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, WidgetRef ref) {
    final provider = addEditRepairJobNotifierProvider(repairJobId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    value: state.status,
                    items: ['Pending', 'In Progress', 'Awaiting Parts', 'Completed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: state.status == 'Completed' ? null : (value) => notifier.setStatus(value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.notes,
              readOnly: state.status == 'Completed',
              decoration: const InputDecoration(
                labelText: 'Notes / Customer Complaint',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: notifier.setNotes,
            ),
          ],
        ),
      ),
    );
  }
}

// --- ADDED: A helper class to group the controllers for a single item ---
class _ItemControllers {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController price;

  _ItemControllers({required String text, required String qty, required String cost})
      : description = TextEditingController(text: text),
        quantity = TextEditingController(text: qty),
        price = TextEditingController(text: cost);

  void dispose() {
    description.dispose();
    quantity.dispose();
    price.dispose();
  }
}


class _EditableItemsList extends ConsumerStatefulWidget {
  final List<RepairJobItem> items;
  final int? jobId;
  final String currencySymbol;

  const _EditableItemsList({
    super.key, 
    required this.items, 
    this.jobId, 
    required this.currencySymbol,
  });

  @override
  ConsumerState<_EditableItemsList> createState() => _EditableItemsListState();
}

class _EditableItemsListState extends ConsumerState<_EditableItemsList> {
  // --- UPDATED: A single map holds the controller group for each item ---
  late Map<RepairJobItem, _ItemControllers> _controllers;
  RepairJobItem? _editingItem;

  @override
  void initState() {
    super.initState();
    _initializeControllers(widget.items);
  }

  void _initializeControllers(List<RepairJobItem> items) {
    _controllers = {
      for (var item in items)
        item: _ItemControllers(
          text: item.description,
          qty: item.quantity.toString(),
          cost: item.unitPrice.toStringAsFixed(2),
        ),
    };
  }
  
  // --- UPDATED: Simplified and more robust lifecycle management ---
  @override
  void didUpdateWidget(_EditableItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const DeepCollectionEquality().equals(widget.items, oldWidget.items)) {
      // Dispose all old controllers that are no longer in the list
      final oldKeys = oldWidget.items.toSet();
      final newKeys = widget.items.toSet();
      final removedKeys = oldKeys.difference(newKeys);
      for (final key in removedKeys) {
        _controllers[key]?.dispose();
      }
      // Re-initialize the controllers map for the new list of items
      _initializeControllers(widget.items);

      if (_editingItem != null && !newKeys.contains(_editingItem)) {
        _editingItem = null;
      }
    }
  }

  @override
  void dispose() {
    for (var controllerGroup in _controllers.values) {
      controllerGroup.dispose();
    }
    super.dispose();
  }
  
  void _saveAndExitEditMode() {
    if (_editingItem != null) {
      final controllers = _controllers[_editingItem]!;
      final newQty = int.tryParse(controllers.quantity.text) ?? _editingItem!.quantity;
      final newPrice = double.tryParse(controllers.price.text) ?? _editingItem!.unitPrice;
      final newDesc = controllers.description.text;
      
      if (newQty != _editingItem!.quantity || newPrice != _editingItem!.unitPrice || newDesc != _editingItem!.description) {
        ref.read(addEditRepairJobNotifierProvider(widget.jobId).notifier).updateItem(
          _editingItem!,
          newQuantity: newQty,
          newPrice: newPrice,
          newDescription: newDesc,
        );
      }
      if (mounted) {
        setState(() {
          _editingItem = null;
        });
      }
    }
  }
  
  void _showDeleteConfirmationDialog(RepairJobItem item) {
    _saveAndExitEditMode();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove "${item.description}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                ref.read(addEditRepairJobNotifierProvider(widget.jobId).notifier).removeItem(item);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isEditing = _editingItem == item;
        final itemControllers = _controllers[item]!;
        
        return InkWell(
          onTap: () {
            if (isEditing) return;
            _saveAndExitEditMode();
            setState(() {
              _editingItem = item;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Row(
              children: [
                if (isEditing && item.itemType == 'Other')
                  Expanded(
                    flex: 3, // Give more space to the description
                    child: TextField(
                      controller: itemControllers.description,
                      autofocus: true,
                      decoration: const InputDecoration(isDense: true, hintText: 'Description'),
                      style: textTheme.bodyLarge,
                      onSubmitted: (_) => _saveAndExitEditMode(),
                    ),
                  )
                else
                  Expanded(flex: 3, child: Text(item.description, style: textTheme.bodyLarge, overflow: TextOverflow.ellipsis,)),
                const SizedBox(width: 16),
                
                isEditing
                    ? Row(
                        children: [
                          Text("Qty: ", style: textTheme.bodySmall),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: itemControllers.quantity,
                              textAlign: TextAlign.center,
                              autofocus: item.itemType != 'Other',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(isDense: true),
                              style: textTheme.bodyLarge,
                              onSubmitted: (_) => _saveAndExitEditMode(),
                            ),
                          ),
                        ],
                      )
                    : Text("Qty: ${item.quantity}", style: textTheme.bodyLarge),

                const SizedBox(width: 16),
                
                isEditing
                    ? Row(
                        children: [
                          Text("Price: ", style: textTheme.bodySmall),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: itemControllers.price,
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(isDense: true),
                              style: textTheme.bodyLarge,
                              onSubmitted: (_) => _saveAndExitEditMode(),
                            ),
                          ),
                        ],
                      )
                    : Text("Price: ${NumberFormat.decimalPattern().format(item.unitPrice)}", style: textTheme.bodyLarge),
                
                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmationDialog(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

