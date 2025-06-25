import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/settings/presentation/workshop_settings_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkshopSettingsScreen extends ConsumerStatefulWidget {
  const WorkshopSettingsScreen({super.key});

  @override
  ConsumerState<WorkshopSettingsScreen> createState() =>
      _WorkshopSettingsScreenState();
}

class _WorkshopSettingsScreenState extends ConsumerState<WorkshopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = ShopSettingsCompanion(
        workshopName: drift.Value(_nameController.text),
        workshopManagerName: drift.Value(_managerController.text),
        workshopPhoneNumber: drift.Value(_phoneController.text),
        workshopAddress: drift.Value(_addressController.text),
      );
      final success = await ref.read(workshopSettingsNotifierProvider.notifier).updateShopSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Settings saved successfully!' : 'Failed to save settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(workshopSettingsProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Workshop Settings', showBackButton: true),
      body: settingsAsync.when(
        data: (settings) {
          _nameController.text = settings.workshopName;
          _managerController.text = settings.workshopManagerName;
          _phoneController.text = settings.workshopPhoneNumber;
          _addressController.text = settings.workshopAddress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Workshop Name*'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _managerController, decoration: const InputDecoration(labelText: 'Owner/Manager Name*'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number*'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address*'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _saveSettings, child: const Text('Save Changes')),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }
}
