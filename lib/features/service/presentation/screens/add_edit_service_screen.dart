// lib/features/service/presentation/screens/add_edit_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/service/presentation/service_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/data/repositories/service_repository.dart'; // Ensure this import is present


class AddEditServiceScreen extends ConsumerStatefulWidget {
  final int? serviceId;

  const AddEditServiceScreen({super.key, this.serviceId});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  bool _isActive = true;

  bool _isLoading = false;
  Service? _currentService;

  bool get _isEditing => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();

    if (_isEditing) {
      _loadServiceData();
    }
  }

  Future<void> _loadServiceData() async {
    setState(() {
      _isLoading = true;
    });
    // Correct way to read provider in ConsumerState
    _currentService = await ref.read(serviceRepositoryProvider).getServiceById(widget.serviceId!);
    if (_currentService != null) {
      _nameController.text = _currentService!.name;
      _descriptionController.text = _currentService!.description ?? '';
      _priceController.text = _currentService!.price.toString();
      _isActive = _currentService!.isActive;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final serviceNotifier = ref.read(serviceNotifierProvider.notifier);

      // This is for adding a new service (using ServicesCompanion)
      final companion = ServicesCompanion(
        id: _isEditing ? Value(widget.serviceId!) : const Value.absent(),
        name: Value(_nameController.text),
        // Use Value.ofNullable when constructing ServicesCompanion
        description: Value.ofNullable(_descriptionController.text.isEmpty ? null : _descriptionController.text),
        price: Value(double.parse(_priceController.text)),
        isActive: Value(_isActive),
      );

      bool success;
      if (_isEditing) {
        // This is for updating an existing service (using Service.copyWith)
        final updatedService = _currentService!.copyWith(
          name: _nameController.text,
          // <--- FIX: Also use Value.ofNullable for copyWith when updating nullable fields!
          description: Value.ofNullable(_descriptionController.text.isEmpty ? null : _descriptionController.text),
          price: double.parse(_priceController.text),
          isActive: _isActive,
        );
        success = await serviceNotifier.updateService(updatedService);
      } else {
        success = await serviceNotifier.addService(companion);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Service updated!' : 'Service added!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Failed to update service.' : 'Failed to add service.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? 'Edit Service' : 'Add Service',
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Service Name*'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter service name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: 'Price*', prefixText: '$currentCurrencySymbol '),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Service is Active'),
                      value: _isActive,
                      onChanged: (bool newValue) {
                        setState(() {
                          _isActive = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveService,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : Text(_isEditing ? 'Update Service' : 'Add Service'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

