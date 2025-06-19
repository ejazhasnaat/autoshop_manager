// lib/features/customer/presentation/screens/add_edit_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Vehicle type
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart'; // For CustomerWithVehicles
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column; // For Value
import 'package:autoshop_manager/features/vehicle_model/presentation/vehicle_model_providers.dart'; // For VehicleModel data

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final int? customerId; // Null for add, has value for edit

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
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
    _currentCustomerWithVehicles = await ref.read(
      customerByIdProvider(widget.customerId!).future,
    );
    if (_currentCustomerWithVehicles != null) {
      final customer = _currentCustomerWithVehicles!.customer;
      _nameController.text = customer.name;
      _phoneNumberController.text = customer.phoneNumber;
      _whatsappNumberController.text = customer.whatsappNumber ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _vehiclesDraft = List.from(
        _currentCustomerWithVehicles!.vehicles,
      ); // Load existing vehicles
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
          const SnackBar(
            content: Text('Please add at least one customer vehicle.'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final customerNotifier = ref.read(customerNotifierProvider.notifier);

      // Determine WhatsApp number: if empty, default to phone number
      final String? finalWhatsappNumber =
          _whatsappNumberController.text.isNotEmpty
          ? _whatsappNumberController.text
          : _phoneNumberController.text; // Default to phone number

      final customerCompanion = CustomersCompanion(
        name: Value(_nameController.text),
        phoneNumber: Value(_phoneNumberController.text),
        whatsappNumber: Value(
          finalWhatsappNumber,
        ), // Use the determined WhatsApp number
        email: Value(
          _emailController.text.isNotEmpty ? _emailController.text : null,
        ),
        address: Value(
          _addressController.text.isNotEmpty ? _addressController.text : null,
        ),
      );

      bool success;
      if (widget.customerId == null) {
        // Add new customer
        final initialVehicleCompanions = _vehiclesDraft
            .map(
              (v) => VehiclesCompanion(
                registrationNumber: Value(v.registrationNumber),
                make: Value(v.make),
                model: Value(v.model),
                year: Value(v.year),
                // customerId will be set by the repository
              ),
            )
            .toList();
        success = await customerNotifier.addCustomer(
          customerCompanion,
          initialVehicleCompanions,
        );
      } else {
        // Update existing customer
        final updatedCustomer = _currentCustomerWithVehicles!.customer.copyWith(
          name: _nameController.text,
          phoneNumber: _phoneNumberController.text,
          whatsappNumber: Value(
            finalWhatsappNumber,
          ), // Use the determined WhatsApp number
          email: Value(
            _emailController.text.isNotEmpty ? _emailController.text : null,
          ),
          address: Value(
            _addressController.text.isNotEmpty ? _addressController.text : null,
          ),
        );
        success = await customerNotifier.updateCustomer(
          updatedCustomer,
          _vehiclesDraft,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customerId == null
                  ? 'Customer added successfully!'
                  : 'Customer updated successfully!',
            ),
          ),
        );
        context.pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customerId == null
                  ? 'Failed to add customer.'
                  : 'Failed to update customer.',
            ),
          ),
        );
      }
    }
  }

  // Method to add/edit a single vehicle via dialog with cascading dropdowns
  void _showVehicleDialog({Vehicle? vehicleToEdit}) {
    final vehicleFormKey = GlobalKey<FormState>();
    final regNoController = TextEditingController(
      text: vehicleToEdit?.registrationNumber,
    );

    // Initial values for dropdowns, use ValueNotifier to manage state within the dialog
    final ValueNotifier<String?> selectedMakeNotifier = ValueNotifier(
      vehicleToEdit?.make,
    );
    final ValueNotifier<String?> selectedModelNotifier = ValueNotifier(
      vehicleToEdit?.model,
    );
    final ValueNotifier<int?> selectedYearNotifier = ValueNotifier(
      vehicleToEdit?.year,
    );

    showDialog(
      context: context,
      builder: (ctx) {
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
                    decoration: const InputDecoration(
                      labelText: 'Registration Number*',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Watch vehicle models inside the dialog's builder for responsiveness
                  Consumer(
                    // Use Consumer to access ref inside the AlertDialog's builder
                    builder: (context, ref, child) {
                      final allVehicleModels = ref
                          .watch(vehicleModelListProvider)
                          .when(
                            data: (models) => models,
                            loading: () =>
                                [], // Return empty list while loading
                            error: (err, stack) {
                              print('Error loading vehicle models: $err');
                              return []; // Return empty list on error
                            },
                          );

                      final uniqueMakes =
                          allVehicleModels.map((vm) => vm.make).toSet().toList()
                            ..sort();

                      return Column(
                        children: [
                          // Make Dropdown
                          ValueListenableBuilder<String?>(
                            valueListenable: selectedMakeNotifier,
                            builder: (context, currentMake, child) {
                              return DropdownButtonFormField<String>(
                                value: currentMake,
                                decoration: const InputDecoration(
                                  labelText: 'Make*',
                                ),
                                items: uniqueMakes.map<DropdownMenuItem<String>>((
                                  make,
                                ) {
                                  // <--- FIX: Explicitly cast to DropdownMenuItem<String>
                                  return DropdownMenuItem<String>(
                                    value: make,
                                    child: Text(make),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  selectedMakeNotifier.value = newValue;
                                  selectedModelNotifier.value =
                                      null; // Reset model when make changes
                                  selectedYearNotifier.value =
                                      null; // Reset year when make changes
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Make is required';
                                  return null;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Model Dropdown
                          ValueListenableBuilder<String?>(
                            valueListenable:
                                selectedMakeNotifier, // Listen to make changes
                            builder: (context, currentMake, child) {
                              final filteredModels =
                                  allVehicleModels
                                      .where((vm) => vm.make == currentMake)
                                      .map((vm) => vm.model)
                                      .toSet()
                                      .toList()
                                    ..sort();

                              // Reset model if current model is not in new filtered list
                              if (selectedModelNotifier.value != null &&
                                  !filteredModels.contains(
                                    selectedModelNotifier.value,
                                  )) {
                                // Check if value is not null before checking contains
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  selectedModelNotifier.value = null;
                                });
                              }

                              return ValueListenableBuilder<String?>(
                                // Listen to model changes for its own value
                                valueListenable: selectedModelNotifier,
                                builder: (context, currentModel, child) {
                                  return DropdownButtonFormField<String>(
                                    value: currentModel,
                                    decoration: const InputDecoration(
                                      labelText: 'Model*',
                                    ),
                                    items: currentMake == null
                                        ? []
                                        : filteredModels.map<
                                            DropdownMenuItem<String>
                                          >((model) {
                                            // <--- FIX: Explicitly cast to DropdownMenuItem<String>
                                            return DropdownMenuItem<String>(
                                              value: model,
                                              child: Text(model),
                                            );
                                          }).toList(),
                                    onChanged:
                                        currentMake ==
                                            null // Disable if no make is selected
                                        ? null
                                        : (newValue) {
                                            selectedModelNotifier.value =
                                                newValue;
                                            selectedYearNotifier.value =
                                                null; // Reset year when model changes
                                          },
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Model is required';
                                      return null;
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Year Dropdown
                          ValueListenableBuilder<String?>(
                            // Listen to make changes
                            valueListenable: selectedMakeNotifier,
                            builder: (context, currentMake, child) {
                              return ValueListenableBuilder<String?>(
                                // Listen to model changes
                                valueListenable: selectedModelNotifier,
                                builder: (context, currentModel, child) {
                                  final selectedVehicleModel = allVehicleModels
                                      .firstWhereOrNull(
                                        (vm) =>
                                            vm.make == currentMake &&
                                            vm.model == currentModel,
                                      );

                                  final List<int> years = [];
                                  if (selectedVehicleModel != null) {
                                    final yearFrom =
                                        selectedVehicleModel.yearFrom ?? 1900;
                                    final yearTo =
                                        selectedVehicleModel.yearTo ??
                                        DateTime.now().year;
                                    for (int i = yearTo; i >= yearFrom; i--) {
                                      years.add(i);
                                    }
                                  }

                                  // Reset year if current year is not in new filtered list
                                  if (selectedYearNotifier.value != null &&
                                      !years.contains(
                                        selectedYearNotifier.value!,
                                      )) {
                                    // Check if value is not null before checking contains
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          selectedYearNotifier.value = null;
                                        });
                                  }

                                  return DropdownButtonFormField<int>(
                                    value: selectedYearNotifier.value,
                                    decoration: const InputDecoration(
                                      labelText: 'Year*',
                                    ),
                                    items: currentModel == null
                                        ? []
                                        : years.map<DropdownMenuItem<int>>((
                                            year,
                                          ) {
                                            // <--- FIX: Explicitly cast to DropdownMenuItem<int>
                                            return DropdownMenuItem<int>(
                                              value: year,
                                              child: Text(year.toString()),
                                            );
                                          }).toList(),
                                    onChanged:
                                        currentModel ==
                                            null // Disable if no model is selected
                                        ? null
                                        : (newValue) {
                                            selectedYearNotifier.value =
                                                newValue;
                                          },
                                    validator: (value) {
                                      if (value == null)
                                        return 'Year is required';
                                      return null;
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
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
                      id:
                          vehicleToEdit?.id ??
                          DateTime.now().microsecondsSinceEpoch.abs() * -1,
                      customerId: vehicleToEdit?.customerId ?? 0,
                      registrationNumber: regNoController.text,
                      make: selectedMakeNotifier.value,
                      model: selectedModelNotifier.value,
                      year: selectedYearNotifier.value,
                    );

                    if (vehicleToEdit == null) {
                      _vehiclesDraft.add(newVehicle);
                    } else {
                      final index = _vehiclesDraft.indexWhere(
                        (v) => v.id == vehicleToEdit.id,
                      );
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
  }

  // Build method for vehicle list in the form
  Widget _buildVehiclesSection() {
    return Column(
      // Changed from Card to Column, as it will be nested in another Card
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Vehicles', // UPDATED TITLE
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ), // REDUCED SIZE
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 30,
              ), // INCREASED SIZE
              onPressed: () =>
                  _showVehicleDialog(), // Call to add a new vehicle
              tooltip: 'Add Vehicle',
            ),
          ],
        ),
        const Divider(height: 24), // Separator
        const SizedBox(height: 8),
        // Display list of added vehicles
        if (_vehiclesDraft.isEmpty &&
            widget.customerId == null) // Only show warning for new customer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Please add at least one customer vehicle.', // UPDATED MESSAGE
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          )
        else if (_vehiclesDraft.isEmpty &&
            widget.customerId !=
                null) // Message for existing customer with no vehicles
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No vehicles associated with this customer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    vehicle.registrationNumber,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${vehicle.make ?? ''} ${vehicle.model ?? ''} ${vehicle.year ?? ''}'
                        .trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showVehicleDialog(vehicleToEdit: vehicle),
                        tooltip: 'Edit Vehicle',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text(
                                'Are you sure you want to delete vehicle "${vehicle.registrationNumber}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _vehiclesDraft.removeAt(index);
                                    });
                                    Navigator.of(ctx).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete Vehicle',
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
                              'Customer Details',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name*',
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Phone Number*',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter customer phone number';
                                }
                                if (value.length < 11 || value.length > 14) {
                                  return 'Phone number must be between 11-14 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 24,
                            ), // Spacing before Vehicles
                            _buildVehiclesSection(), // Moved inside Required group
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
                          'Optionals',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded:
                            false, // <--- UPDATED: Starts collapsed
                        childrenPadding: const EdgeInsets.all(16.0),
                        children: [
                          TextFormField(
                            controller: _whatsappNumberController,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp Number',
                            ), // Removed "(Optional)"
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (value.length < 11 || value.length > 14)) {
                                return 'WhatsApp number must be between 11-14 digits or empty';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ), // Removed "(Optional)"
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                            ), // Removed "(Optional)"
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading ||
                                (widget.customerId == null &&
                                    _vehiclesDraft.isEmpty))
                            ? null
                            : _saveCustomer,
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              )
                            : Text(
                                widget.customerId == null
                                    ? 'Add Customer'
                                    : 'Update Customer',
                              ),
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
