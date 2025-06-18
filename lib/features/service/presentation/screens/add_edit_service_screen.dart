// lib/features/service/presentation/screens/add_edit_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Service and ServicesCompanion
import 'package:autoshop_manager/features/service/presentation/service_providers.dart'; // For serviceNotifierProvider and serviceByIdProvider
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // For CommonAppBar
import 'package:drift/drift.dart' hide Column; // For Value

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final int? serviceId; // Null for add, has value for edit

  const AddEditServiceScreen({super.key, this.serviceId});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  bool _isActive = true; // Default for new service

  bool _isLoading = false;
  Service? _currentService;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();

    if (widget.serviceId != null) {
      _loadServiceData();
    }
  }

  Future<void> _loadServiceData() async {
    setState(() {
      _isLoading = true;
    });
    _currentService = await ref.read(serviceByIdProvider(widget.serviceId!).future); // Fetch service data
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

      bool success;
      if (widget.serviceId == null) {
        // Add new service
        final newServiceCompanion = ServicesCompanion(
          name: Value(_nameController.text),
          description: Value(_descriptionController.text.isNotEmpty ? _descriptionController.text : null),
          price: Value(double.parse(_priceController.text)),
          isActive: Value(_isActive),
        );
        success = await serviceNotifier.addService(newServiceCompanion);
      } else {
        // Update existing service
        final updatedService = _currentService!.copyWith(
          name: _nameController.text,
          description: Value(_descriptionController.text.isNotEmpty ? _descriptionController.text : null),
          price: double.parse(_priceController.text),
          isActive: _isActive,
        );
        success = await serviceNotifier.updateService(updatedService);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.serviceId == null ? 'Service added successfully!' : 'Service updated successfully!')),
        );
        context.pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.serviceId == null ? 'Failed to add service.' : 'Failed to update service.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.serviceId == null ? 'Add New Service' : 'Edit Service',
        showBackButton: true, // Show back button on add/edit screen
      ),
      body: _isLoading && widget.serviceId != null
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
                      decoration: const InputDecoration(labelText: 'Service Name'),
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
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isActive,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _isActive = newValue ?? false;
                            });
                          },
                        ),
                        const Text('Service is Active'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveService,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : Text(widget.serviceId == null ? 'Add Service' : 'Update Service'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

