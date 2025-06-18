// lib/features/inventory/presentation/screens/add_edit_inventory_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/data/repositories/inventory_repository.dart'; // <--- NEW IMPORT for inventoryRepositoryProvider
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column; // <--- NEW IMPORT for Value


class AddEditInventoryItemScreen extends ConsumerStatefulWidget {
  final int? itemId; // Null for add, has value for edit

  const AddEditInventoryItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddEditInventoryItemScreen> createState() => _AddEditInventoryItemScreenState();
}

class _AddEditInventoryItemScreenState extends ConsumerState<AddEditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _partNumberController;
  late TextEditingController _supplierController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _stockLocationController;

  bool _isLoading = false;
  InventoryItem? _currentItem;

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

    if (widget.itemId != null) {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    setState(() {
      _isLoading = true;
    });
    _currentItem = await ref.read(inventoryRepositoryProvider).getInventoryItemById(widget.itemId!);
    if (_currentItem != null) {
      _nameController.text = _currentItem!.name;
      _partNumberController.text = _currentItem!.partNumber;
      _supplierController.text = _currentItem!.supplier ?? '';
      _costPriceController.text = _currentItem!.costPrice.toString();
      _salePriceController.text = _currentItem!.salePrice.toString();
      _quantityController.text = _currentItem!.quantity.toString();
      _stockLocationController.text = _currentItem!.stockLocation ?? '';
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

  Future<void> _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final inventoryNotifier = ref.read(inventoryNotifierProvider.notifier);

      final companion = InventoryItemsCompanion(
        name: Value(_nameController.text),
        partNumber: Value(_partNumberController.text),
        supplier: Value(_supplierController.text.isNotEmpty ? _supplierController.text : null),
        costPrice: Value(double.parse(_costPriceController.text)),
        salePrice: Value(double.parse(_salePriceController.text)),
        quantity: Value(int.parse(_quantityController.text)),
        stockLocation: Value(_stockLocationController.text.isNotEmpty ? _stockLocationController.text : null),
      );

      bool success;
      if (widget.itemId == null) {
        // Add new item
        success = await inventoryNotifier.addInventoryItem(companion);
      } else {
        // Update existing item
        final updatedItem = _currentItem!.copyWith(
          name: _nameController.text,
          partNumber: _partNumberController.text,
          supplier: Value(_supplierController.text.isNotEmpty ? _supplierController.text : null),
          costPrice: double.parse(_costPriceController.text),
          salePrice: double.parse(_salePriceController.text),
          quantity: int.parse(_quantityController.text),
          stockLocation: Value(_stockLocationController.text.isNotEmpty ? _stockLocationController.text : null),
        );
        success = await inventoryNotifier.updateInventoryItem(updatedItem);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.itemId == null ? 'Item added successfully!' : 'Item updated successfully!')),
        );
        context.pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.itemId == null ? 'Failed to add item.' : 'Failed to update item.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.itemId == null ? 'Add Inventory Item' : 'Edit Inventory Item',
        showBackButton: true,
      ),
      body: _isLoading && widget.itemId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _partNumberController,
                      decoration: const InputDecoration(labelText: 'Part Number'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter part number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(labelText: 'Supplier (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(labelText: 'Cost Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid cost price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _salePriceController,
                      decoration: const InputDecoration(labelText: 'Sale Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid sale price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockLocationController,
                      decoration: const InputDecoration(labelText: 'Stock Location (Optional)'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveItem,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : Text(widget.itemId == null ? 'Add Item' : 'Update Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

