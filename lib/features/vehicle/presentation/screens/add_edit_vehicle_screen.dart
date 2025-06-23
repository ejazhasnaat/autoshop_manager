// lib/features/vehicle/presentation/screens/add_edit_vehicle_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_model_providers.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/add_edit_customer_screen.dart';


class AddEditVehicleScreen extends ConsumerStatefulWidget {
  final int? vehicleId;
  final int? customerId;
  final bool isDraftMode;

  const AddEditVehicleScreen({
    super.key,
    this.vehicleId,
    this.customerId,
    this.isDraftMode = false,
  });

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.vehicleId != null;

  // --- FIX: Added state variable to hold the loaded vehicle data ---
  Vehicle? _loadedVehicle;

  late final TextEditingController _regController;
  late final TextEditingController _mileageController;
  late final TextEditingController _lastServiceMileageController;
  late final TextEditingController _engineOilMileageController;
  late final TextEditingController _gearOilMileageController;

  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;

  DateTime? _lastServiceDate;
  DateTime? _engineOilDate;
  DateTime? _gearOilDate;

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController();
    _mileageController = TextEditingController();
    _lastServiceMileageController = TextEditingController();
    _engineOilMileageController = TextEditingController();
    _gearOilMileageController = TextEditingController();

    if (_isEditing) {
      _loadVehicleData();
    }
  }

  Future<void> _loadVehicleData() async {
    final vehicle = await ref.read(vehicleByIdProvider(widget.vehicleId!).future);
    if (vehicle != null && mounted) {
      // --- FIX: Store the loaded vehicle to preserve all its data ---
      _loadedVehicle = vehicle;
      setState(() {
        _regController.text = vehicle.registrationNumber;
        _selectedMake = vehicle.make;
        _selectedModel = vehicle.model;
        _selectedYear = vehicle.year;
        _mileageController.text = vehicle.currentMileage?.toString() ?? '';
        _lastServiceMileageController.text = vehicle.lastGeneralServiceMileage?.toString() ?? '';
        _engineOilMileageController.text = vehicle.lastEngineOilChangeMileage?.toString() ?? '';
        _gearOilMileageController.text = vehicle.lastGearOilChangeMileage?.toString() ?? '';
        _lastServiceDate = vehicle.lastGeneralServiceDate;
        _engineOilDate = vehicle.lastEngineOilChangeDate;
        _gearOilDate = vehicle.lastGearOilChangeDate;
      });
    }
  }

  @override
  void dispose() {
    _regController.dispose();
    _mileageController.dispose();
    _lastServiceMileageController.dispose();
    _engineOilMileageController.dispose();
    _gearOilMileageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? currentDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      final vehicleDao = ref.read(vehicleDaoProvider);
      final existingVehicle = await vehicleDao.getVehicleByRegNo(_regController.text);

      if (existingVehicle != null && existingVehicle.id != widget.vehicleId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Registration number ${_regController.text} already exists.')),
          );
        }
        return;
      }
      
      // --- FIX: Preserve existing reminder data when editing ---
      // This now correctly includes the new required fields.
      final vehicleData = Vehicle(
        id: widget.vehicleId ?? DateTime.now().microsecondsSinceEpoch * -1,
        customerId: widget.customerId ?? 0,
        registrationNumber: _regController.text,
        make: _selectedMake,
        model: _selectedModel,
        year: _selectedYear,
        currentMileage: int.tryParse(_mileageController.text),
        lastGeneralServiceMileage: int.tryParse(_lastServiceMileageController.text),
        lastEngineOilChangeMileage: int.tryParse(_engineOilMileageController.text),
        lastGearOilChangeMileage: int.tryParse(_gearOilMileageController.text),
        lastGeneralServiceDate: _lastServiceDate,
        lastEngineOilChangeDate: _engineOilDate,
        lastGearOilChangeDate: _gearOilDate,
        // --- ADDED: Include new fields to fix compile error and prevent data loss ---
        isReminderActive: _isEditing ? _loadedVehicle!.isReminderActive : true,
        reminderSnoozedUntil: _isEditing ? _loadedVehicle!.reminderSnoozedUntil : null,
        nextReminderDate: _isEditing ? _loadedVehicle!.nextReminderDate : null,
        nextReminderType: _isEditing ? _loadedVehicle!.nextReminderType : null,
      );

      if (widget.isDraftMode) {
        context.pop(vehicleData);
        return;
      }
      
      final notifier = ref.read(vehicleNotifierProvider.notifier);
      bool success;
      if (_isEditing) {
        success = await notifier.updateVehicle(vehicleData);
      } else {
        success = await notifier.addVehicle(vehicleData.toCompanion(true));
      }

      if (mounted && success) {
        ref.invalidate(customerNotifierProvider);
        ref.invalidate(customerByIdProvider(widget.customerId!));
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save vehicle.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allVehicleModelsAsync = ref.watch(vehicleModelListProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _regController,
                decoration: const InputDecoration(labelText: 'Registration Number*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              allVehicleModelsAsync.when(
                data: (allModels) {
                  final uniqueMakes = allModels.map((vm) => vm.make).toSet().toList()..sort();
                  final filteredModels = allModels.where((vm) => vm.make == _selectedMake).map((vm) => vm.model).toSet().toList()..sort();
                  final selectedDbModel = allModels.firstWhereOrNull((vm) => vm.make == _selectedMake && vm.model == _selectedModel);

                  final List<int> years = [];
                  if (selectedDbModel != null) {
                    final yearFrom = selectedDbModel.yearFrom ?? 1900;
                    final yearTo = selectedDbModel.yearTo ?? DateTime.now().year;
                    for (int i = yearTo; i >= yearFrom; i--) {
                      years.add(i);
                    }
                  }

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedMake,
                        decoration: const InputDecoration(labelText: 'Make*'),
                        items: uniqueMakes.map((make) => DropdownMenuItem(value: make, child: Text(make))).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedMake = newValue;
                            _selectedModel = null;
                            _selectedYear = null;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a make' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedModel,
                        decoration: const InputDecoration(labelText: 'Model*'),
                        items: filteredModels.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                        onChanged: _selectedMake == null ? null : (newValue) {
                          setState(() {
                            _selectedModel = newValue;
                            _selectedYear = null;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a model' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(labelText: 'Year*'),
                          items: years.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                          onChanged: _selectedModel == null ? null : (newValue) {
                              setState(() {
                                _selectedYear = newValue;
                              });
                            },
                          validator: (v) => v == null ? 'Please select a year' : null,
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading models: $e'),
              ),

              const Divider(height: 30),
              Text('Service & Mileage Info', style: Theme.of(context).textTheme.titleLarge),
               const SizedBox(height: 10),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Current Mileage (km)'),
                keyboardType: TextInputType.number,
              ),
              _buildDateAndMileageRow(context, 'Last Service', _lastServiceDate, (date) => _lastServiceDate = date, _lastServiceMileageController),
              _buildDateAndMileageRow(context, 'Engine Oil Change', _engineOilDate, (date) => _engineOilDate = date, _engineOilMileageController),
              _buildDateAndMileageRow(context, 'Gear Oil Change', _gearOilDate, (date) => _gearOilDate = date, _gearOilMileageController),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveVehicle, child: const Text('Save Vehicle')),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateAndMileageRow(
      BuildContext context,
      String label,
      DateTime? date,
      Function(DateTime) onDateSelected,
      TextEditingController mileageController) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _selectDate(context, date, onDateSelected),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '$label Date',
                ),
                child: Text(
                  date != null ? DateFormat.yMMMd().format(date) : 'Select Date',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: mileageController,
              decoration: const InputDecoration(labelText: 'at Mileage'),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}
