// lib/features/repair_job/presentation/screens/add_edit_repair_job_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/features/service/presentation/service_providers.dart';
import 'package:autoshop_manager/features/repair_job/presentation/notifiers/add_edit_repair_job_notifier.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class AddEditRepairJobScreen extends ConsumerStatefulWidget {
  final int? repairJobId;

  const AddEditRepairJobScreen({super.key, this.repairJobId});

  @override
  ConsumerState<AddEditRepairJobScreen> createState() => _AddEditRepairJobScreenState();
}

class _AddEditRepairJobScreenState extends ConsumerState<AddEditRepairJobScreen> {
  final _scrollController = ScrollController();
  final _othersListKey = GlobalKey<_EditableItemsListState>();
  final _servicesListKey = GlobalKey<_EditableItemsListState>();
  final _partsListKey = GlobalKey<_EditableItemsListState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId).notifier);
    final hasChanges = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId)).hasChanges;

    if (!hasChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.saveJob();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = addEditRepairJobNotifierProvider(widget.repairJobId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final isNewJob = widget.repairJobId == null;
    final preferencesAsync = ref.watch(userPreferencesStreamProvider);

    void _saveAllEdits() {
      _othersListKey.currentState?._saveAndExitEditMode();
      _servicesListKey.currentState?._saveAndExitEditMode();
      _partsListKey.currentState?._saveAndExitEditMode();
      FocusScope.of(context).unfocus();
    }

    // UPDATED: Logic to determine if the save button should be enabled.
    // It now requires a vehicle to be selected in addition to other conditions.
    final canSave = (isNewJob || state.hasChanges) && state.selectedVehicle != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context, ref);
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: CommonAppBar(
          title: isNewJob ? 'New Repair Job' : 'Edit Repair Job',
        ),
        body: GestureDetector(
          onTap: _saveAllEdits,
          child: preferencesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text("Error loading settings: $err")),
              data: (prefs) {
                final currencySymbol = prefs.defaultCurrency;
                return state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCustomerAndVehicleSection(context, ref),
                                  const SizedBox(height: 4),
                                  _buildDetailsCard(context, ref),
                                  const SizedBox(height: 8),
                                  _buildItemsSection(context, ref, 'Services', _servicesListKey, currencySymbol),
                                  const SizedBox(height: 8),
                                  _buildItemsSection(context, ref, 'Parts', _partsListKey, currencySymbol),
                                  const SizedBox(height: 8),
                                  _buildItemsSection(context, ref, 'Others', _othersListKey, currencySymbol),
                                  const SizedBox(height: 8),
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
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _BottomActionBar(
                          isNewJob: isNewJob,
                          canSave: canSave, // UPDATED: Pass the calculated boolean
                          onCancel: () {
                            context.go('/home');
                          },
                          onCreate: () async {
                            _saveAllEdits();
                            final savedId = await notifier.saveJob();
                            if(context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isNewJob ? 'Job Created!' : 'Job Updated!'), 
                                  backgroundColor: Colors.green
                                ),
                              );
                              context.go('/home');
                            }
                          },
                        ),
                      ],
                    );
              }),
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, WidgetRef ref, String title, Key key, String currencySymbol) {
    final state = ref.watch(addEditRepairJobNotifierProvider(widget.repairJobId));
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
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          '(tap on item to edit)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(isService ? 'Add Service' : (isPart ? 'Add Part' : 'Add Other')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.selectedVehicle == null || state.status == 'Completed'
                          ? null
                          : () {
                              (key as GlobalKey<_EditableItemsListState>).currentState?._saveAndExitEditMode();
                              if (isService) _showAddServiceDialog(context, ref, currencySymbol);
                              else if (isPart) _showAddPartDialog(context, ref);
                              else _showAddOtherDialog(context, ref);
                            },
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Sub-Total: ${NumberFormat.currency(symbol: '$currencySymbol ').format(subTotal)}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
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
                jobId: widget.repairJobId,
                currencySymbol: currencySymbol,
              ),
          ],
        ),
      ),
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
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
                  ),
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                     validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == 0) ? 'Enter a valid quantity' : null,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Enter a valid price' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref.read(addEditRepairJobNotifierProvider(widget.repairJobId).notifier).addOtherItem(
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
          TextButton(onPressed: () { Navigator.of(dialogContext).pop(); onAddNew(); }, child: const Text('Add as New')),
          ElevatedButton(onPressed: () { Navigator.of(dialogContext).pop(); onIncrement(); }, child: const Text('Increase Quantity')),
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
            final notifier = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId).notifier);
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
                        decoration: const InputDecoration(labelText: 'Search by service or category...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        onChanged: (value) => ref.read(serviceSearchQueryProvider.notifier).state = value,
                      ),
                    ),
                    Expanded(
                      child: servicesAsync.when(
                        data: (services) {
                          if (services.isEmpty) return const Center(child: Text('No services found.'));
                          final groupedServices = groupBy(services, (Service s) => s.category);
                          return ListView.builder(
                            itemCount: groupedServices.keys.length,
                            itemBuilder: (context, index) {
                              final category = groupedServices.keys.elementAt(index);
                              final serviceItems = groupedServices[category]!;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ExpansionTile(
                                  title: Text("$category (${serviceItems.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  children: serviceItems.map((service) {
                                    return ListTile(
                                      title: Text(service.name),
                                      trailing: Text(numberFormat.format(service.price)),
                                      onTap: () {
                                        final jobItems = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId)).items;
                                        final existingItem = jobItems.firstWhereOrNull((item) => item.itemType == 'Service' && item.linkedItemId == service.id);
                                        if (existingItem != null) {
                                          _showDuplicateItemDialog(context: context, itemName: service.name, onIncrement: () { notifier.incrementItemQuantity(existingItem); Navigator.of(context).pop(); }, onAddNew: () { notifier.addServiceItem(service); Navigator.of(context).pop(); });
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
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
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
          final notifier = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId).notifier);

          void attemptToAddItem(InventoryItem item, int quantity) {
            final success = notifier.addInventoryItem(item, quantity);
            if (consumerContext.mounted) Navigator.of(consumerContext).pop();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add part: Not enough items in stock.'), backgroundColor: Colors.red));
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
                      decoration: const InputDecoration(labelText: 'Search by Name, Number, or Make', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      onChanged: (value) => ref.read(inventoryNotifierProvider.notifier).applyFiltersAndSort(searchTerm: value),
                    ),
                  ),
                  Expanded(
                    child: inventoryAsync.when(
                      data: (items) {
                        if (items.isEmpty) return const Center(child: Text('No parts found.'));
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('In Stock: ${item.quantity}'),
                              onTap: () {
                                final jobItems = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId)).items;
                                final existingItem = jobItems.firstWhereOrNull((jobItem) => jobItem.itemType == 'InventoryItem' && jobItem.linkedItemId == item.id);
                                if (existingItem != null) {
                                  _showDuplicateItemDialog(context: consumerContext, itemName: item.name, onIncrement: () { notifier.incrementItemQuantity(existingItem); Navigator.of(consumerContext).pop(); }, onAddNew: () => attemptToAddItem(item, 1));
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
            actions: [TextButton(onPressed: () => Navigator.of(consumerContext).pop(), child: const Text('Cancel'))],
          );
        },
      ),
    );
  }

  Widget _buildCustomerAndVehicleSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addEditRepairJobNotifierProvider(widget.repairJobId));
    final notifier = ref.read(addEditRepairJobNotifierProvider(widget.repairJobId).notifier);
    final customersAsync = ref.watch(customerListProvider);
    final vehicles = state.selectedCustomerWithVehicles?.vehicles ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: customersAsync.when(
                data: (customers) => DropdownButtonFormField<CustomerWithVehicles>(
                  value: state.selectedCustomerWithVehicles,
                  hint: const Text('Select a Customer'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder()),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.customer.name))).toList(),
                  onChanged: state.status == 'Completed' ? null : (customer) {
                    if (customer != null) notifier.setCustomer(customer);
                  },
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<Vehicle>(
                value: state.selectedVehicle,
                hint: const Text('Select a Vehicle'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vehicle', border: OutlineInputBorder()),
                items: vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.make} ${v.model} - ${v.registrationNumber}'))).toList(),
                onChanged: state.selectedCustomerWithVehicles == null || state.status == 'Completed' ? null : (vehicle) {
                  if (vehicle != null) notifier.setVehicle(vehicle);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, WidgetRef ref) {
    final provider = addEditRepairJobNotifierProvider(widget.repairJobId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final List<String> statusOptions = [
      'In Progress',
      'Queued',
      'Awaiting Parts',
      'Quality Check',
    ];

    if (state.status != null && !statusOptions.contains(state.status)) {
      statusOptions.add(state.status!);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    value: state.priority,
                    items: ['Normal', 'High', 'Urgent'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: state.status == 'Completed' ? null : (value) => notifier.setPriority(value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    value: state.status,
                    items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: state.status == 'Completed' ? null : (value) => notifier.setStatus(value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.notes,
              readOnly: state.status == 'Completed',
              decoration: const InputDecoration(labelText: 'Notes / Customer Complaint', border: OutlineInputBorder(), alignLabelWithHint: true),
              minLines: 1,
              maxLines: 5,
              onChanged: notifier.setNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isNewJob;
  final bool canSave; // UPDATED: Replaced hasChanges with canSave
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const _BottomActionBar({
    required this.isNewJob,
    required this.canSave, // UPDATED
    required this.onCancel,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    // REMOVED: Internal logic is no longer needed.
    final buttonText = isNewJob ? 'Create Repair Job' : 'Update Repair Job';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: canSave ? onCreate : null, // UPDATED: Use canSave directly
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: Text(buttonText),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: const Text('Cancel'),
          ),
        ],
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
  
  @override
  void didUpdateWidget(_EditableItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const DeepCollectionEquality().equals(widget.items, oldWidget.items)) {
      final oldKeys = oldWidget.items.toSet();
      final newKeys = widget.items.toSet();
      final removedKeys = oldKeys.difference(newKeys);
      for (final key in removedKeys) {
        _controllers[key]?.dispose();
      }
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
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () { ref.read(addEditRepairJobNotifierProvider(widget.jobId).notifier).removeItem(item); Navigator.of(dialogContext).pop(); },
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
                // Column 1: Item Name (Left Aligned)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: isEditing && item.itemType == 'Other'
                      ? TextField(
                          controller: itemControllers.description,
                          autofocus: true,
                          decoration: const InputDecoration(isDense: true, hintText: 'Description'),
                          style: textTheme.bodyLarge,
                          onSubmitted: (_) => _saveAndExitEditMode(),
                        )
                      : Text(item.description, style: textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                  ),
                ),
                
                // Column 2: Qty + Price (Center Aligned)
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: isEditing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: itemControllers.quantity, 
                                textAlign: TextAlign.center, 
                                autofocus: item.itemType != 'Other', 
                                keyboardType: TextInputType.number, 
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                decoration: const InputDecoration(isDense: true, labelText: 'Qty'), 
                                style: textTheme.bodyLarge, 
                                onSubmitted: (_) => _saveAndExitEditMode()
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: itemControllers.price, 
                                textAlign: TextAlign.center, 
                                keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                                decoration: const InputDecoration(isDense: true, labelText: 'Price'), 
                                style: textTheme.bodyLarge, 
                                onSubmitted: (_) => _saveAndExitEditMode()
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Qty: ${item.quantity}", style: textTheme.bodyLarge),
                            const SizedBox(width: 16),
                            Text("Price: ${NumberFormat.decimalPattern().format(item.unitPrice)}", style: textTheme.bodyLarge),
                          ],
                        ),
                  ),
                ),
                
                // Column 3: Delete Icon (Right Aligned)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _showDeleteConfirmationDialog(item)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

