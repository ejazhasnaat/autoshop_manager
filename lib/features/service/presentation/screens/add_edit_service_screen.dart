// lib/features/service/presentation/screens/add_edit_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/service/presentation/service_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/data/repositories/service_repository.dart';

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
  late TextEditingController _categoryController;
  bool _isLoading = false;
  Service? _currentService;
  bool get _isEditing => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _categoryController = TextEditingController();
    if (_isEditing) {
      _loadServiceData();
    }
  }

  Future<void> _loadServiceData() async {
    setState(() => _isLoading = true);
    _currentService = await ref.read(serviceRepositoryProvider).getServiceById(widget.serviceId!);
    if (_currentService != null) {
      _nameController.text = _currentService!.name;
      _descriptionController.text = _currentService!.description ?? '';
      _priceController.text = _currentService!.price.toString();
      _categoryController.text = _currentService!.category;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _generateSlug(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _saveService() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final serviceNotifier = ref.read(serviceNotifierProvider.notifier);
      final repo = ref.read(serviceRepositoryProvider);
      late final String serviceCode;

      if (!_isEditing || _nameController.text != _currentService!.name) {
        serviceCode = _generateSlug(_nameController.text);
        final exists = await repo.serviceExists(serviceCode);
        if (exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: A service with a similar name already exists.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        serviceCode = _currentService!.serviceCode;
      }

      bool success;
      if (_isEditing) {
        final serviceToUpdate = Service(
          id: widget.serviceId!,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _categoryController.text,
          serviceCode: serviceCode,
          isActive: _currentService!.isActive, // Keep existing value
        );
        success = await serviceNotifier.updateService(serviceToUpdate);
      } else {
        final companion = ServicesCompanion(
          name: Value(_nameController.text),
          description: Value(_descriptionController.text),
          price: Value(double.parse(_priceController.text)),
          category: Value(_categoryController.text),
          serviceCode: Value(serviceCode),
        );
        success = await serviceNotifier.addService(companion);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Service updated!' : 'Service added!')));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Failed to update service.' : 'Failed to add service.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);
    return Scaffold(
      appBar: CommonAppBar(title: _isEditing ? 'Edit Service' : 'Add Service', showBackButton: true),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Service Name*', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category*', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price*',
                        prefixText: '$currentCurrencySymbol ',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Please enter a valid price' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveService,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? 'Update Service' : 'Add Service'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
