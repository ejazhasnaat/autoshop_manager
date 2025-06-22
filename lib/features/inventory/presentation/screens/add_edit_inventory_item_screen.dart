// lib/features/inventory/presentation/screens/add_edit_inventory_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For InventoryItem type
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // For CommonAppBar
import 'package:drift/drift.dart' hide Column; // For Value
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_model_providers.dart'; // For vehicle models
import 'package:autoshop_manager/features/customer/presentation/screens/add_edit_customer_screen.dart'; // For IterableExtension
import 'package:autoshop_manager/data/repositories/inventory_repository.dart'; // For inventoryRepositoryProvider
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart'; // <--- NEW IMPORT

class AddEditInventoryItemScreen extends ConsumerStatefulWidget {
  final int? itemId; // Null for add, has value for edit

  const AddEditInventoryItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddEditInventoryItemScreen> createState() =>
      _AddEditInventoryItemScreenState(); // <--- FIX: Correct return type
}

class _AddEditInventoryItemScreenState
    extends ConsumerState<AddEditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _partNumberController;
  late TextEditingController _supplierController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _stockLocationController;

  // Variables for vehicle association
  String? _selectedVehicleMake;
  String? _selectedVehicleModel;
  int? _selectedVehicleYearFrom;
  int? _selectedVehicleYearTo;

  bool _isLoading = false;
  InventoryItem? _currentInventoryItem;

  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _partNumberController = TextEditingController();
    _supplierController = TextEditingController();
    _costPriceController = TextEditingController();
    _salePriceController = TextEditingController();
    _quantityController = TextEditingController();
    _stockLocationController = TextEditingController();

    if (_isEditing) {
      _loadInventoryItemData();
    }
  }

  Future<void> _loadInventoryItemData() async {
    setState(() {
      _isLoading = true;
    });
    _currentInventoryItem = await ref
        .read(inventoryRepositoryProvider)
        .getInventoryItemById(widget.itemId!);
    if (_currentInventoryItem != null) {
      _nameController.text = _currentInventoryItem!.name;
      _partNumberController.text = _currentInventoryItem!.partNumber ?? '';
      _supplierController.text = _currentInventoryItem!.supplier ?? '';
      _costPriceController.text = _currentInventoryItem!.costPrice.toString();
      _salePriceController.text = _currentInventoryItem!.salePrice.toString();
      _quantityController.text = _currentInventoryItem!.quantity.toString();
      _stockLocationController.text =
          _currentInventoryItem!.stockLocation ?? '';

      _selectedVehicleMake = _currentInventoryItem!.vehicleMake;
      _selectedVehicleModel = _currentInventoryItem!.vehicleModel;
      _selectedVehicleYearFrom = _currentInventoryItem!.vehicleYearFrom;
      _selectedVehicleYearTo = _currentInventoryItem!.vehicleYearTo;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _supplierController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _stockLocationController.dispose();
    super.dispose();
  }

  Future<void> _saveInventoryItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final inventoryNotifier = ref.read(inventoryNotifierProvider.notifier);

      final companion = InventoryItemsCompanion(
        id: _isEditing ? Value(widget.itemId!) : const Value.absent(),
        name: Value(_nameController.text),
        partNumber: Value(
          _partNumberController.text.isNotEmpty
              ? _partNumberController.text
              : null,
        ),
        supplier: Value(
          _supplierController.text.isNotEmpty ? _supplierController.text : null,
        ),
        costPrice: Value(double.parse(_costPriceController.text)),
        salePrice: Value(double.parse(_salePriceController.text)),
        quantity: Value(int.parse(_quantityController.text)),
        stockLocation: Value(
          _stockLocationController.text.isNotEmpty
              ? _stockLocationController.text
              : null,
        ),
        vehicleMake: Value(_selectedVehicleMake),
        vehicleModel: Value(_selectedVehicleModel),
        vehicleYearFrom: Value(_selectedVehicleYearFrom),
        vehicleYearTo: Value(_selectedVehicleYearTo),
      );

      bool success;
      if (_isEditing) {
        final updatedItem = InventoryItem(
          id: widget.itemId!,
          name: _nameController.text,
          partNumber: _partNumberController.text.isNotEmpty
              ? _partNumberController.text
              : null,
          supplier: _supplierController.text.isNotEmpty
              ? _supplierController.text
              : null,
          costPrice: double.parse(_costPriceController.text),
          salePrice: double.parse(_salePriceController.text),
          quantity: int.parse(_quantityController.text),
          stockLocation: _stockLocationController.text.isNotEmpty
              ? _stockLocationController.text
              : null,
          vehicleMake: _selectedVehicleMake,
          vehicleModel: _selectedVehicleModel,
          vehicleYearFrom: _selectedVehicleYearFrom,
          vehicleYearTo: _selectedVehicleYearTo,
        );
        success = await inventoryNotifier.updateInventoryItem(updatedItem);
      } else {
        success = await inventoryNotifier.addInventoryItem(companion);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Inventory item updated!' : 'Inventory item added!',
            ),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Failed to update item.' : 'Failed to add item.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleModelsAsync = ref.watch(vehicleModelListProvider);
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? 'Edit Inventory Item' : 'Add Inventory Item',
        showBackButton: true,
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Required Fields Group ---
                    Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Required Details',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Item Name*',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter item name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _costPriceController,
                              decoration: InputDecoration(
                                labelText: 'Cost Price*',
                                prefixText: '$currentCurrencySymbol ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    double.tryParse(value) == null) {
                                  return 'Please enter a valid cost price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _salePriceController,
                              decoration: InputDecoration(
                                labelText: 'Sale Price*',
                                prefixText: '$currentCurrencySymbol ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    double.tryParse(value) == null) {
                                  return 'Please enter a valid sale price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity*',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    int.tryParse(value) == null) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Optional Details Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Optional Details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: false,
                        childrenPadding: const EdgeInsets.all(16.0),
                        children: [
                          TextFormField(
                            controller: _partNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Part Number',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _supplierController,
                            decoration: const InputDecoration(
                              labelText: 'Supplier',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stockLocationController,
                            decoration: const InputDecoration(
                              labelText: 'Stock Location',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Vehicle Compatibility Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Vehicle Compatibility',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: false,
                        childrenPadding: const EdgeInsets.all(16.0),
                        children: [
                          vehicleModelsAsync.when(
                            data: (vehicleModels) {
                              final uniqueMakes =
                                  vehicleModels
                                      .map((vm) => vm.make)
                                      .toSet()
                                      .toList()
                                    ..sort();

                              final filteredModels =
                                  vehicleModels
                                      .where(
                                        (vm) => vm.make == _selectedVehicleMake,
                                      )
                                      .map((vm) => vm.model)
                                      .toSet()
                                      .toList()
                                    ..sort();

                              final selectedVehicleModel = vehicleModels
                                  .firstWhereOrNull(
                                    (vm) =>
                                        vm.make == _selectedVehicleMake &&
                                        vm.model == _selectedVehicleModel,
                                  );

                              final List<int> yearsFrom = [];
                              final List<int> yearsTo = [];
                              if (selectedVehicleModel != null) {
                                final yearFrom =
                                    selectedVehicleModel.yearFrom ?? 1900;
                                final yearTo =
                                    selectedVehicleModel.yearTo ??
                                    DateTime.now().year;
                                for (int i = yearTo; i >= yearFrom; i--) {
                                  yearsFrom.add(i);
                                  yearsTo.add(i);
                                }
                              }

                              return Column(
                                children: [
                                  // Make Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedVehicleMake,
                                    decoration: const InputDecoration(
                                      labelText: 'Make',
                                    ),
                                    items: uniqueMakes.map((make) {
                                      return DropdownMenuItem(
                                        value: make,
                                        child: Text(make),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedVehicleMake = newValue;
                                        _selectedVehicleModel = null;
                                        _selectedVehicleYearFrom = null;
                                        _selectedVehicleYearTo = null;
                                      });
                                    },
                                    hint: const Text('Select Make'),
                                  ),
                                  const SizedBox(height: 16),
                                  // Model Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedVehicleModel,
                                    decoration: const InputDecoration(
                                      labelText: 'Model',
                                    ),
                                    items: _selectedVehicleMake == null
                                        ? []
                                        : filteredModels.map((model) {
                                            return DropdownMenuItem(
                                              value: model,
                                              child: Text(model),
                                            );
                                          }).toList(),
                                    onChanged: _selectedVehicleMake == null
                                        ? null
                                        : (newValue) {
                                            setState(() {
                                              _selectedVehicleModel = newValue;
                                              _selectedVehicleYearFrom = null;
                                              _selectedVehicleYearTo = null;
                                            });
                                          },
                                    hint: const Text('Select Model'),
                                  ),
                                  const SizedBox(height: 16),
                                  // Year From Dropdown
                                  DropdownButtonFormField<int>(
                                    value: _selectedVehicleYearFrom,
                                    decoration: const InputDecoration(
                                      labelText: 'Year From',
                                    ),
                                    items: _selectedVehicleModel == null
                                        ? []
                                        : yearsFrom.map((year) {
                                            return DropdownMenuItem(
                                              value: year,
                                              child: Text(year.toString()),
                                            );
                                          }).toList(),
                                    onChanged: _selectedVehicleModel == null
                                        ? null
                                        : (newValue) {
                                            setState(() {
                                              _selectedVehicleYearFrom =
                                                  newValue;
                                              if (_selectedVehicleYearTo !=
                                                      null &&
                                                  _selectedVehicleYearTo! <
                                                      newValue!) {
                                                _selectedVehicleYearTo =
                                                    newValue;
                                              }
                                            });
                                          },
                                    hint: const Text('Select Year From'),
                                  ),
                                  const SizedBox(height: 16),
                                  // Year To Dropdown
                                  DropdownButtonFormField<int>(
                                    value: _selectedVehicleYearTo,
                                    decoration: const InputDecoration(
                                      labelText: 'Year To',
                                    ),
                                    items: _selectedVehicleYearFrom == null
                                        ? []
                                        : yearsTo
                                              .where(
                                                (year) =>
                                                    _selectedVehicleYearFrom ==
                                                        null ||
                                                    year >=
                                                        _selectedVehicleYearFrom!,
                                              )
                                              .map((year) {
                                                return DropdownMenuItem(
                                                  value: year,
                                                  child: Text(year.toString()),
                                                );
                                              })
                                              .toList(),
                                    onChanged: _selectedVehicleYearFrom == null
                                        ? null
                                        : (newValue) {
                                            setState(() {
                                              _selectedVehicleYearTo = newValue;
                                            });
                                          },
                                    hint: const Text('Select Year To'),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                            loading: () =>
                                const CircularProgressIndicator.adaptive(),
                            error: (err, stack) => Center(
                              child: Text('Error loading vehicle models: $err'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveInventoryItem,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              )
                            : Text(_isEditing ? 'Update Item' : 'Add Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
