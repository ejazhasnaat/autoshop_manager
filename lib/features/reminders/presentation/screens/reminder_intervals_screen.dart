import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderIntervalsScreen extends ConsumerStatefulWidget {
  const ReminderIntervalsScreen({super.key});

  @override
  ConsumerState<ReminderIntervalsScreen> createState() =>
      _ReminderIntervalsScreenState();
}

class _ReminderIntervalsScreenState extends ConsumerState<ReminderIntervalsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _engineKmController;
  late TextEditingController _engineMonthsController;
  late TextEditingController _gearKmController;
  late TextEditingController _gearMonthsController;
  late TextEditingController _generalKmController;
  late TextEditingController _generalMonthsController;

  @override
  void initState() {
    super.initState();
    _engineKmController = TextEditingController();
    _engineMonthsController = TextEditingController();
    _gearKmController = TextEditingController();
    _gearMonthsController = TextEditingController();
    _generalKmController = TextEditingController();
    _generalMonthsController = TextEditingController();
    _loadSettings();
  }

  void _loadSettings() {
    ref.read(preferenceRepositoryProvider).getPreferences().then((prefs) {
      if (mounted) {
        setState(() {
          _engineKmController.text = prefs.engineOilIntervalKm.toString();
          _engineMonthsController.text = prefs.engineOilIntervalMonths.toString();
          _gearKmController.text = prefs.gearOilIntervalKm.toString();
          _gearMonthsController.text = prefs.gearOilIntervalMonths.toString();
          _generalKmController.text = prefs.generalServiceIntervalKm.toString();
          _generalMonthsController.text = prefs.generalServiceIntervalMonths.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _engineKmController.dispose();
    _engineMonthsController.dispose();
    _gearKmController.dispose();
    _gearMonthsController.dispose();
    _generalKmController.dispose();
    _generalMonthsController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final currentPrefs = await ref.read(preferenceRepositoryProvider).getPreferences();
      final newPrefs = currentPrefs.copyWith(
        engineOilIntervalKm: int.parse(_engineKmController.text),
        engineOilIntervalMonths: int.parse(_engineMonthsController.text),
        gearOilIntervalKm: int.parse(_gearKmController.text),
        gearOilIntervalMonths: int.parse(_gearMonthsController.text),
        generalServiceIntervalKm: int.parse(_generalKmController.text),
        generalServiceIntervalMonths: int.parse(_generalMonthsController.text),
      );

      final success = await ref.read(settingsNotifierProvider.notifier).savePreferences(newPrefs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Intervals saved!' : 'Failed to save intervals.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UPDATED: Using the new showCloseButton property ---
      appBar: const CommonAppBar(title: 'Reminder Intervals', showCloseButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSettingsCard(
                context,
                title: 'Set Service Intervals',
                children: [
                  _buildIntervalRow('Engine Oil', _engineKmController, _engineMonthsController),
                  _buildIntervalRow('Gear Oil', _gearKmController, _gearMonthsController),
                  _buildIntervalRow('General Service', _generalKmController, _generalMonthsController),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Intervals'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalRow(String label, TextEditingController kmController, TextEditingController monthsController) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: kmController,
                  decoration: const InputDecoration(labelText: 'Kilometers (km)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: monthsController,
                  decoration: const InputDecoration(labelText: 'Months', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
