// lib/features/customer/presentation/screens/add_edit_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart'; // For CustomerWithVehicles
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column; // For Value
import 'package:autoshop_manager/features/vehicle_model/presentation/vehicle_model_providers.dart'; // <--- NEW IMPORT for VehicleModel data

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final int? customerId; // Null for add, has value for edit

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _whatsappNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool _isLoading = false;
  CustomerWithVehicles? _currentCustomerWithVehicles;
  List<Vehicle> _vehiclesDraft = []; // For managing vehicles in the form

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _whatsappNumberController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();

    if (widget.customerId != null) {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
    });
    _currentCustomerWithVehicles = await ref.read(customerByIdProvider(widget.customerId!).future);
    if (_currentCustomerWithVehicles != null) {
      final customer = _currentCustomerWithVehicles!.customer;
      _nameController.text = customer.name;
      _phoneNumberController.text = customer.phoneNumber;
      _whatsappNumberController.text = customer.whatsappNumber ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _vehiclesDraft = List.from(_currentCustomerWithVehicles!.vehicles); // Load existing vehicles
    }
    setState(() {
      _isLoading = false;
    });
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

  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate that at least one vehicle is added if it's a new customer
      if (widget.customerId == null && _vehiclesDraft.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one vehicle (Registration Number is required).')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final customerNotifier = ref.read(customerNotifierProvider.notifier);

      final customerCompanion = CustomersCompanion(
        name: Value(_nameController.text),
        phoneNumber: Value(_phoneNumberController.text),
        whatsappNumber: Value(_whatsappNumberController.text.isNotEmpty ? _whatsappNumberController.text : null), // <--- FIX: Corrected typo
        email: Value(_emailController.text.isNotEmpty ? _emailController.text : null),
        address: Value(_addressController.text.isNotEmpty ? _addressController.text : null),
      );

      bool success;
      if (widget.customerId == null) {
        // Add new customer
        final initialVehicleCompanions = _vehiclesDraft.map((v) => VehiclesCompanion(
          registrationNumber: Value(v.registrationNumber),
          make: Value(v.make),
          model: Value(v.model),
          year: Value(v.year),
          // customerId will be set by the repository
        )).toList();
        success = await customerNotifier.addCustomer(customerCompanion, initialVehicleCompanions);
      } else {
        // Update existing customer
        final updatedCustomer = _currentCustomerWithVehicles!.customer.copyWith(
          name: _nameController.text,
          phoneNumber: _phoneNumberController.text,
          whatsappNumber: Value(_whatsappNumberController.text.isNotEmpty ? _whatsappNumberController.text : null), // <--- FIX: Corrected typo
          email: Value(_emailController.text.isNotEmpty ? _emailController.text : null),
          address: Value(_addressController.text.isNotEmpty ? _addressController.text : null),
        );
        success = await customerNotifier.updateCustomer(updatedCustomer, _vehiclesDraft);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.customerId == null ? 'Customer added successfully!' : 'Customer updated successfully!')),
        );
        context.pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.customerId == null ? 'Failed to add customer.' : 'Failed to update customer.')),
        );
      }
    }
  }

  // Method to add/edit a single vehicle via dialog with cascading dropdowns
  void _showVehicleDialog({Vehicle? vehicleToEdit}) {
    final vehicleFormKey = GlobalKey<FormState>();
    final regNoController = TextEditingController(text: vehicleToEdit?.registrationNumber);

    // Initial values for dropdowns
    String? initialMake = vehicleToEdit?.make;
    String? initialModel = vehicleToEdit?.model;
    int? initialYear = vehicleToEdit?.year;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( // Use StatefulBuilder for dynamic dialog content
          builder: (context, setDialogState) {
            final vehicleModelsAsync = ref.watch(vehicleModelListProvider);

            return AlertDialog(
              title: Text(vehicleToEdit == null ? 'Add Vehicle' : 'Edit Vehicle'),
              content: SingleChildScrollView(
                child: Form(
                  key: vehicleFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: regNoController,
                        decoration: const InputDecoration(labelText: 'Registration Number*'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      vehicleModelsAsync.when(
                        data: (vehicleModels) {
                          final uniqueMakes = vehicleModels.map((vm) => vm.make).toSet().toList()..sort();
                          
                          // Filter models based on selected make
                          final filteredModels = vehicleModels
                              .where((vm) => vm.make == initialMake)
                              .map((vm) => vm.model)
                              .toSet()
                              .toList()..sort();

                          // Get selected model to determine year range
                          final selectedVehicleModel = vehicleModels.firstWhereOrNull(
                                  (vm) => vm.make == initialMake && vm.model == initialModel);

                          final List<int> years = [];
                          if (selectedVehicleModel != null) {
                            final yearFrom = selectedVehicleModel.yearFrom ?? 1900; // Default start year
                            final yearTo = selectedVehicleModel.yearTo ?? DateTime.now().year; // Default end year
                            for (int i = yearTo; i >= yearFrom; i--) {
                              years.add(i);
                            }
                          }

                          return Column(
                            children: [
                              // Make Dropdown
                              DropdownButtonFormField<String>(
                                value: initialMake,
                                decoration: const InputDecoration(labelText: 'Make*'),
                                items: uniqueMakes.map((make) {
                                  return DropdownMenuItem(value: make, child: Text(make));
                                }).toList(),
                                onChanged: (newValue) {
                                  setDialogState(() {
                                    initialMake = newValue;
                                    initialModel = null; // Reset model when make changes
                                    initialYear = null;  // Reset year when make changes
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Make is required';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Model Dropdown
                              DropdownButtonFormField<String>(
                                value: initialModel,
                                decoration: const InputDecoration(labelText: 'Model*'),
                                items: initialMake == null // <--- FIX: Disable if no make is selected
                                    ? []
                                    : filteredModels.map((model) {
                                  return DropdownMenuItem(value: model, child: Text(model));
                                }).toList(),
                                onChanged: initialMake == null // <--- FIX: Conditionally set onChanged to null
                                    ? null
                                    : (newValue) {
                                  setDialogState(() {
                                    initialModel = newValue;
                                    initialYear = null; // Reset year when model changes
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Model is required';
                                  return null;
                                },
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 16),
                              // Year Dropdown
                              DropdownButtonFormField<int>(
                                value: initialYear,
                                decoration: const InputDecoration(labelText: 'Year*'),
                                items: initialModel == null // <--- FIX: Disable if no model is selected
                                    ? []
                                    : years.map((year) {
                                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                                }).toList(),
                                onChanged: initialModel == null // <--- FIX: Conditionally set onChanged to null
                                    ? null
                                    : (newValue) {
                                  setDialogState(() {
                                    initialYear = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) return 'Year is required';
                                  return null;
                                },
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator.adaptive(),
                        error: (err, stack) => Center(child: Text('Error loading vehicle models: $err')),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (vehicleFormKey.currentState?.validate() ?? false) {
                      setState(() {
                        final newVehicle = Vehicle(
                          id: vehicleToEdit?.id ?? DateTime.now().microsecondsSinceEpoch.abs() * -1,
                          customerId: vehicleToEdit?.customerId ?? 0,
                          registrationNumber: regNoController.text,
                          make: initialMake,    // Use selected make
                          model: initialModel,  // Use selected model
                          year: initialYear,    // Use selected year
                        );

                        if (vehicleToEdit == null) {
                          _vehiclesDraft.add(newVehicle);
                        } else {
                          final index = _vehiclesDraft.indexWhere((v) => v.id == vehicleToEdit.id);
                          if (index != -1) {
                            _vehiclesDraft[index] = newVehicle;
                          }
                        }
                      });
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(vehicleToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build method for vehicle list in the form
  Widget _buildVehiclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vehicles (at least one required)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showVehicleDialog(), // Call to add a new vehicle
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Display list of added vehicles
        if (_vehiclesDraft.isEmpty && widget.customerId == null) // Only show warning for new customer
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No vehicles added. Please add at least one.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vehiclesDraft.length,
            itemBuilder: (context, index) {
              final vehicle = _vehiclesDraft[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(vehicle.registrationNumber),
                  subtitle: Text('${vehicle.make ?? ''} ${vehicle.model ?? ''} ${vehicle.year ?? ''}'.trim()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showVehicleDialog(vehicleToEdit: vehicle),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _vehiclesDraft.removeAt(index);
                          });
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.customerId == null ? 'Add Customer' : 'Edit Customer',
        showBackButton: true,
      ),
      body: _isLoading && widget.customerId != null
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
                      decoration: const InputDecoration(labelText: 'Customer Name*'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number*'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (value.length < 11 || value.length > 14) {
                          return 'Phone number must be between 11-14 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _whatsappNumberController,
                      decoration: const InputDecoration(labelText: 'WhatsApp Number (Optional)'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && (value.length < 11 || value.length > 14)) {
                          return 'WhatsApp number must be between 11-14 digits or empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email (Optional)'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address (Optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Vehicles Section
                    _buildVehiclesSection(),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Disable if no vehicles are added for new customer or if form is loading
                        onPressed: (_isLoading || (widget.customerId == null && _vehiclesDraft.isEmpty))
                            ? null
                            : _saveCustomer,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : Text(widget.customerId == null ? 'Add Customer' : 'Update Customer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Extension to easily find an element in a list
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

