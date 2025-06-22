// lib/features/customer/presentation/screens/add_edit_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column;

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final int? customerId;

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _whatsappNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // This list holds vehicles for a NEW customer before they are saved.
  List<Vehicle> _vehiclesDraft = [];
  
  // A helper flag to ensure we only populate the form controllers once.
  bool _controllersPopulated = false;

  @override
  void initState() {
    super.initState();
    // No listeners needed, logic is handled explicitly now.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _whatsappNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  void _populateControllers(CustomerWithVehicles customerWithVehicles) {
    final customer = customerWithVehicles.customer;
    _nameController.text = customer.name;
    _phoneNumberController.text = customer.phoneNumber;
    _whatsappNumberController.text = customer.whatsappNumber ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.customerId == null && _vehiclesDraft.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one customer vehicle.')),
        );
        return;
      }

      final customerNotifier = ref.read(customerNotifierProvider.notifier);
      
      final String finalWhatsappNumber = _whatsappNumberController.text.isNotEmpty
          ? _whatsappNumberController.text
          : _phoneNumberController.text;

      bool success;
      if (widget.customerId == null) {
        final customerCompanion = CustomersCompanion(
          name: Value(_nameController.text),
          phoneNumber: Value(_phoneNumberController.text),
          whatsappNumber: Value(finalWhatsappNumber),
          email: Value(_emailController.text.isNotEmpty ? _emailController.text : null),
          address: Value(_addressController.text.isNotEmpty ? _addressController.text : null),
        );
        final initialVehicleCompanions = _vehiclesDraft.map((v) => v.toCompanion(true)).toList();
        success = await customerNotifier.addCustomer(customerCompanion, initialVehicleCompanions);
      } else {
        final currentCustomer = ref.read(customerByIdProvider(widget.customerId!)).value!.customer;
        final updatedCustomer = currentCustomer.copyWith(
          name: _nameController.text,
          phoneNumber: _phoneNumberController.text,
          whatsappNumber: Value(finalWhatsappNumber),
          email: Value(_emailController.text.isNotEmpty ? _emailController.text : null),
          address: Value(_addressController.text.isNotEmpty ? _addressController.text : null),
        );
        
        // FIX: Removed the unnecessary vehicle list and updated the call.
        // The notifier now only needs the updated customer object.
        success = await customerNotifier.updateCustomer(updatedCustomer);
      }

      if (mounted && success) {
        ref.invalidate(customerListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.customerId == null ? 'Customer added successfully!' : 'Customer updated successfully!')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.customerId == null ? 'Failed to add customer.' : 'Failed to update customer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = widget.customerId != null 
        ? ref.watch(customerByIdProvider(widget.customerId!)) 
        : const AsyncValue.data(null);

    if (customerAsync.hasValue && customerAsync.value != null && !_controllersPopulated) {
      _populateControllers(customerAsync.value!);
      _controllersPopulated = true;
    }
    
    final isLoading = customerAsync.isLoading;

    return Scaffold(
      appBar: CommonAppBar(
        title: widget.customerId == null ? 'Add Customer' : 'Edit Customer',
        showBackButton: true,
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading customer: $err')),
        data: (customerData) {
          final vehicles = customerData?.vehicles ?? _vehiclesDraft;
          return _buildForm(isLoading, vehicles);
        },
      ),
    );
  }

  Widget _buildForm(bool isLoading, List<Vehicle> vehicles) {
    return SingleChildScrollView(
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
                    Text('Customer Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name*'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter customer name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number*'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter customer phone number';
                        if (value.length < 11 || value.length > 14) return 'Phone number must be between 11-14 digits';
                        return null;
                      },
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
                child: _buildVehiclesSection(vehicles),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text('Optional Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                initiallyExpanded: false,
                childrenPadding: const EdgeInsets.all(16.0).copyWith(top: 0),
                children: [
                  TextFormField(
                    controller: _whatsappNumberController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      helperText: 'Leave empty to use phone number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && (value.length < 11 || value.length > 14)) return 'WhatsApp number must be between 11-14 digits or empty';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveCustomer,
                child: isLoading
                    ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                    : Text(widget.customerId == null ? 'Add Customer' : 'Update Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesSection(List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Customer Vehicles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              onPressed: () async {
                if (widget.customerId != null) {
                  await context.push('/vehicles/add/${widget.customerId}');
                  ref.invalidate(customerByIdProvider(widget.customerId!));
                } else {
                  final newDraftVehicle = await context.push<Vehicle>('/vehicles/add_draft');
                  if (newDraftVehicle != null) {
                    setState(() {
                      _vehiclesDraft.add(newDraftVehicle);
                    });
                  }
                }
              },
            ),
          ],
        ),
        const Divider(height: 24),
        if (vehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No vehicles added yet.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(
                    vehicle.registrationNumber,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${vehicle.make ?? ''} ${vehicle.model ?? ''} ${vehicle.year ?? ''}'.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: (widget.customerId == null) 
                    ? IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                        onPressed: () {
                           setState(() => _vehiclesDraft.removeAt(index));
                        },
                        tooltip: 'Remove Vehicle',
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Vehicle',
                        onPressed: () async {
                          await context.push('/vehicles/edit/${vehicle.id}?customerId=${widget.customerId}');
                          ref.invalidate(customerByIdProvider(widget.customerId!));
                        },
                      ),
                ),
              );
            },
          ),
      ],
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
