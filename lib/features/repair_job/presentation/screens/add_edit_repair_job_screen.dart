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

  final _servicesListKey = GlobalKey<_EditableItemsListState>();
  final _partsListKey = GlobalKey<_EditableItemsListState>();

  AddEditRepairJobScreen({super.key, this.repairJobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesKey = _servicesListKey;
    final partsKey = _partsListKey;

    final provider = addEditRepairJobNotifierProvider(repairJobId);
    final state = ref.watch(provider);
    final isNewJob = repairJobId == null;
    final preferencesAsync = ref.watch(userPreferencesStreamProvider);

    void _saveAllEdits() {
      servicesKey.currentState?._saveAndExitEditMode();
      partsKey.currentState?._saveAndExitEditMode();
      FocusScope.of(context).unfocus();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                            await ref
                                .read(provider.notifier)
                                .completeAndBillJob();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Job Completed!'),
                                  backgroundColor: Colors.green),
                            );
                            context.pop();
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
    final isService = title == 'Services';
    final items = isService
        ? state.items.where((i) => i.itemType == 'Service').toList()
        : state.items.where((i) => i.itemType == 'InventoryItem').toList();
    
    final subTotal = isService ? state.servicesTotalCost : state.partsTotalCost;

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
              label: Text(isService ? 'Add Service' : 'Add Part'),
              onPressed: state.selectedVehicle == null || state.status == 'Completed'
                  ? null
                  : () {
                      // --- FIX: Access the keys directly from the parent build context ---
                      // This is the robust way to access the keys.
                      (key as GlobalKey<_EditableItemsListState>).currentState?._saveAndExitEditMode();
                      // --- END FIX ---
                      
                      if (isService) {
                        _showAddServiceDialog(context, ref, currencySymbol);
                      } else {
                        _showAddPartDialog(context, ref);
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
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final inventoryAsync = ref.watch(inventoryNotifierProvider);
          final notifier = ref.read(addEditRepairJobNotifierProvider(repairJobId).notifier);

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
                                    context: context,
                                    itemName: item.name,
                                    onIncrement: () {
                                      notifier.incrementItemQuantity(existingItem);
                                      Navigator.of(context).pop();
                                    },
                                    onAddNew: () {
                                      notifier.addInventoryItem(item, 1);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                } else {
                                  notifier.addInventoryItem(item, 1);
                                  Navigator.of(context).pop();
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
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))
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
  late Map<RepairJobItem, TextEditingController> _qtyControllers;
  late Map<RepairJobItem, TextEditingController> _priceControllers;
  RepairJobItem? _editingItem;

  @override
  void initState() {
    super.initState();
    _initializeControllers(widget.items);
  }

  void _initializeControllers(List<RepairJobItem> items) {
    _qtyControllers = {
      for (var item in items)
        item: TextEditingController(text: item.quantity.toString()),
    };
    _priceControllers = {
      for (var item in items)
        item: TextEditingController(text: item.unitPrice.toStringAsFixed(2)),
    };
  }

  @override
  void didUpdateWidget(_EditableItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const DeepCollectionEquality().equals(widget.items, oldWidget.items)) {
      final oldItems = oldWidget.items.toSet();
      final newItems = widget.items.toSet();
      final removedItems = oldItems.difference(newItems);
      for (var item in removedItems) {
        _qtyControllers[item]?.dispose();
        _priceControllers[item]?.dispose();
      }
      
      if (_editingItem != null && !newItems.contains(_editingItem)) {
        _editingItem = null;
      }
      _initializeControllers(widget.items);
    }
  }

  @override
  void dispose() {
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _saveAndExitEditMode() {
    if (_editingItem != null) {
      final newQty = int.tryParse(_qtyControllers[_editingItem]!.text) ?? _editingItem!.quantity;
      final newPrice = double.tryParse(_priceControllers[_editingItem]!.text) ?? _editingItem!.unitPrice;
      
      if (newQty != _editingItem!.quantity || newPrice != _editingItem!.unitPrice) {
        ref.read(addEditRepairJobNotifierProvider(widget.jobId).notifier).updateItem(
          _editingItem!,
          newQuantity: newQty,
          newPrice: newPrice,
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
                Expanded(child: Text(item.description, style: textTheme.bodyLarge)),
                const SizedBox(width: 8),
                
                isEditing
                    ? Row(
                        children: [
                          Text("Qty: ", style: textTheme.bodyLarge),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _qtyControllers[item]!,
                              textAlign: TextAlign.left,
                              autofocus: true,
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
                          Text("Price (${widget.currencySymbol}): ", style: textTheme.bodyLarge),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _priceControllers[item]!,
                              textAlign: TextAlign.left,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(isDense: true),
                              style: textTheme.bodyLarge,
                              onSubmitted: (_) => _saveAndExitEditMode(),
                            ),
                          ),
                        ],
                      )
                    : Text("Price (${widget.currencySymbol}): ${NumberFormat.decimalPattern().format(item.unitPrice)}", style: textTheme.bodyLarge),
                
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
