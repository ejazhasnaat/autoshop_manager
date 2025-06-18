// lib/features/vehicle_model/presentation/screens/add_edit_vehicle_model_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For VehicleModel and VehicleModelsCompanion
import 'package:autoshop_manager/features/vehicle_model/presentation/vehicle_model_providers.dart'; // For vehicleModelNotifierProvider
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' hide Column; // For Value

class AddEditVehicleModelScreen extends ConsumerStatefulWidget {
  final String? make; // Null for add, has value for edit
  final String? model; // Null for add, has value for edit

  const AddEditVehicleModelScreen({super.key, this.make, this.model});

  @override
  ConsumerState<AddEditVehicleModelScreen> createState() => _AddEditVehicleModelScreenState();
}

class _AddEditVehicleModelScreenState extends ConsumerState<AddEditVehicleModelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearFromController; // <--- FIX: Corrected controller name
  late TextEditingController _yearToController;    // <--- FIX: Added controller for yearTo

  bool _isLoading = false;
  VehicleModel? _currentVehicleModel;

  bool get _isEditing => widget.make != null && widget.model != null;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _yearFromController = TextEditingController(); // Initialize
    _yearToController = TextEditingController();    // Initialize

    if (_isEditing) {
      _loadVehicleModelData();
    }
  }

  Future<void> _loadVehicleModelData() async {
    setState(() {
      _isLoading = true;
    });
    // <--- FIX: Use vehicleModelByMakeModelProvider with make and model --->
    _currentVehicleModel = await ref.read(vehicleModelByMakeModelProvider((widget.make!, widget.model!)).future);
    if (_currentVehicleModel != null) {
      _makeController.text = _currentVehicleModel!.make;
      _modelController.text = _currentVehicleModel!.model;
      _yearFromController.text = _currentVehicleModel!.yearFrom?.toString() ?? '';
      _yearToController.text = _currentVehicleModel!.yearTo?.toString() ?? '';
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearFromController.dispose(); // Dispose
    _yearToController.dispose();    // Dispose
    super.dispose();
  }

  Future<void> _saveVehicleModel() async { // <--- FIX: Renamed _saveModel to _saveVehicleModel
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final notifier = ref.read(vehicleModelNotifierProvider.notifier);

      bool success;
      if (_isEditing) {
        // Update existing vehicle model
        final updatedModel = _currentVehicleModel!.copyWith(
          make: _makeController.text, // Make and model are part of the primary key, but copyWith allows updating them if needed for a new entry.
          model: _modelController.text, // If changing PK, it's effectively a delete + insert.
          yearFrom: Value(int.tryParse(_yearFromController.text)),
          yearTo: Value(int.tryParse(_yearToController.text)),
        );
        success = await notifier.updateVehicleModel(updatedModel);
      } else {
        // Add new vehicle model
        final newModelCompanion = VehicleModelsCompanion.insert(
          make: _makeController.text,
          model: _modelController.text, // <--- FIX: Corrected parameter name from 'getModel' to 'model'
          yearFrom: Value(int.tryParse(_yearFromController.text)),
          yearTo: Value(int.tryParse(_yearToController.text)),
        );
        success = await notifier.addVehicleModel(newModelCompanion);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Vehicle model updated successfully!' : 'Vehicle model added successfully!')),
        );
        context.pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Failed to update vehicle model.' : 'Failed to add vehicle model (might already exist).')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? 'Edit Vehicle Model' : 'Add New Vehicle Model', // <--- FIX: Removed widget.modelId
        showBackButton: true,
      ),
      body: _isLoading && _isEditing // <--- FIX: Removed widget.modelId
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(labelText: 'Make*'),
                      enabled: !_isEditing, // Disable make field when editing (part of composite key)
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter make';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model*'),
                      enabled: !_isEditing, // Disable model field when editing (part of composite key)
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter model';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearFromController, // <--- FIX: Use _yearFromController
                      decoration: const InputDecoration(labelText: 'Year From (Optional)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final year = int.tryParse(value);
                          if (year == null) {
                            return 'Enter a valid year';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearToController, // <--- FIX: Use _yearToController
                      decoration: const InputDecoration(labelText: 'Year To (Optional)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final year = int.tryParse(value);
                          if (year == null) {
                            return 'Enter a valid year';
                          }
                          // Optional: Add logic to ensure yearTo is >= yearFrom if both are present
                          final yearFrom = int.tryParse(_yearFromController.text ?? '');
                          if (yearFrom != null && year < yearFrom) {
                            return 'Year To cannot be before Year From';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveVehicleModel, // <--- FIX: Use _saveVehicleModel
                        child: _isLoading
                            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                            : Text(_isEditing ? 'Update Model' : 'Add Model'), // <--- FIX: Removed widget.modelId
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

