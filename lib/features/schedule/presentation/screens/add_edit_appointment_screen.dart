// lib/features/schedule/presentation/screens/add_edit_appointment_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/schedule/presentation/notifiers/add_edit_appointment_notifier.dart';
import 'package:autoshop_manager/features/schedule/presentation/schedule_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddEditAppointmentScreen extends ConsumerStatefulWidget {
  const AddEditAppointmentScreen({super.key});

  @override
  ConsumerState<AddEditAppointmentScreen> createState() =>
      _AddEditAppointmentScreenState();
}

class _AddEditAppointmentScreenState
    extends ConsumerState<AddEditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _technicianController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _servicesDisplayController = TextEditingController();


  @override
  void dispose() {
    _technicianController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _servicesDisplayController.dispose();
    super.dispose();
  }
  
  Future<void> _showMultiSelectServicesDialog() async {
    final notifier = ref.read(addEditAppointmentNotifierProvider.notifier);
    final state = ref.read(addEditAppointmentNotifierProvider);

    final selectedServices = await showDialog<List<Service>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          allItems: state.allServices,
          initiallySelectedItems: state.selectedServices,
        );
      },
    );

    if (selectedServices != null) {
      notifier.onServicesSelected(selectedServices);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEditAppointmentNotifierProvider);
    final notifier = ref.read(addEditAppointmentNotifierProvider.notifier);
    final theme = Theme.of(context);

    _servicesDisplayController.text = state.selectedServices.map((s) => s.name).join(', ');

    ref.listen<AddEditAppointmentState>(addEditAppointmentNotifierProvider, (previous, next) {
      if (next.saveSuccess == true && previous?.saveSuccess != true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Appointment created successfully!'),
              backgroundColor: Colors.green));
        
        context.go('/home');
      } 
      else if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: theme.colorScheme.error));
      }
    });

    return Scaffold(
      appBar: const CommonAppBar(title: 'New Appointment'),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCustomerVehicleCard(context, state, notifier),
                    const SizedBox(height: 16),
                    _buildServiceDetailsCard(context, state),
                    const SizedBox(height: 16),
                    _buildSchedulingCard(context, notifier),
                    const SizedBox(height: 24),
                    _buildActionButtons(state, notifier),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerVehicleCard(BuildContext context,
      AddEditAppointmentState state, AddEditAppointmentNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer & Vehicle',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _customerDropdown(state, notifier)),
                      const SizedBox(width: 16),
                      Expanded(child: _vehicleDropdown(state, notifier)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _customerDropdown(state, notifier),
                    const SizedBox(height: 16),
                    _vehicleDropdown(state, notifier),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DropdownButtonFormField<Customer> _customerDropdown(
      AddEditAppointmentState state, AddEditAppointmentNotifier notifier) {
    return DropdownButtonFormField<Customer>(
      value: state.selectedCustomer,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Customer *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: state.customers
          .map((cwv) => DropdownMenuItem(
                value: cwv.customer,
                child: Text(
                  '${cwv.customer.name} - ${cwv.customer.phoneNumber}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: notifier.customerSelected,
      validator: (value) =>
          value == null ? 'Please select a customer' : null,
    );
  }

  DropdownButtonFormField<Vehicle> _vehicleDropdown(
      AddEditAppointmentState state, AddEditAppointmentNotifier notifier) {
    return DropdownButtonFormField<Vehicle>(
      value: state.selectedVehicle,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Vehicle *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.directions_car_outlined),
        enabled: state.selectedCustomer != null,
      ),
      items: state.vehiclesForSelectedCustomer
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(
                  '${v.year} ${v.make} ${v.model} (${v.registrationNumber})',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged:
          state.selectedCustomer != null ? notifier.vehicleSelected : null,
      validator: (value) => value == null ? 'Please select a vehicle' : null,
    );
  }

  Widget _buildServiceDetailsCard(
      BuildContext context, AddEditAppointmentState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _servicesDisplayController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Services Required *',
                hintText: 'Tap to select services',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build_outlined),
              ),
              onTap: _showMultiSelectServicesDialog,
              validator: (value) =>
                  state.selectedServices.isEmpty ? 'Please select at least one service' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _technicianController,
              decoration: const InputDecoration(
                labelText: 'Assigned Technician',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.engineering_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingCard(
      BuildContext context, AddEditAppointmentNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduling', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _datePickerField(notifier)),
                      const SizedBox(width: 16),
                      Expanded(child: _timePickerField(notifier)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _datePickerField(notifier),
                    const SizedBox(height: 16),
                    _timePickerField(notifier),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _datePickerField(AddEditAppointmentNotifier notifier) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          _dateController.text = DateFormat.yMMMMd().format(pickedDate);
          notifier.onDateSelected(pickedDate);
        }
      },
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please select a date' : null,
    );
  }

  TextFormField _timePickerField(AddEditAppointmentNotifier notifier) {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Time *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.access_time_outlined),
      ),
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          _timeController.text = pickedTime.format(context);
          notifier.onTimeSelected(pickedTime);
        }
      },
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please select a time' : null,
    );
  }

  Widget _buildActionButtons(
      AddEditAppointmentState state, AddEditAppointmentNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: state.isSaving ? null : () => context.go('/home'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: state.isSaving
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    notifier.createAppointment(
                      technician: _technicianController.text,
                      notes: _notesController.text,
                    );
                  }
                },
          icon: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
          label:
              Text(state.isSaving ? 'Creating...' : 'Create Appointment'),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<Service> allItems;
  final List<Service> initiallySelectedItems;

  const MultiSelectDialog({
    super.key,
    required this.allItems,
    required this.initiallySelectedItems,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late final Set<Service> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = Set.from(widget.initiallySelectedItems);
  }

  void _onItemCheckedChange(Service item, bool isChecked) {
    setState(() {
      if (isChecked) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Services'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: widget.allItems.length,
          itemBuilder: (context, index) {
            final item = widget.allItems[index];
            return CheckboxListTile(
              title: Text(item.name),
              value: _selectedItems.contains(item),
              onChanged: (isChecked) => _onItemCheckedChange(item, isChecked!),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedItems.toList()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
