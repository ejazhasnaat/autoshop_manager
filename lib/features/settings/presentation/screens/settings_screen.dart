// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _supportedCurrencies = const ['PKR', 'USD', 'EUR', 'GBP', 'JPY'];
  
  late TextEditingController _engineKmController;
  late TextEditingController _engineMonthsController;
  late TextEditingController _gearKmController;
  late TextEditingController _gearMonthsController;
  late TextEditingController _generalKmController;
  late TextEditingController _generalMonthsController;
  String? _currentCurrency;

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
    // We read the repository directly for one-time initial values.
    ref.read(preferenceRepositoryProvider).getPreferences().then((prefs) {
      if (mounted) {
        setState(() {
          _currentCurrency = prefs.defaultCurrency;
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
      final newPrefs = UserPreferences(
        defaultCurrency: _currentCurrency ?? 'PKR',
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
          SnackBar(content: Text(success ? 'Settings saved!' : 'Failed to save settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Settings', showBackButton: true),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err')),
        data: (prefs) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSettingsCard(
                    context,
                    title: 'General Settings',
                    children: [
                      ListTile(
                        title: const Text('Default Currency'),
                        subtitle: DropdownButtonFormField<String>(
                          value: _currentCurrency,
                          items: _supportedCurrencies.map((String currency) {
                            return DropdownMenuItem<String>(value: currency, child: Text(currency));
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _currentCurrency = newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    context,
                    title: 'Reminder Intervals',
                    children: [
                      _buildIntervalRow('Engine Oil', _engineKmController, _engineMonthsController),
                      _buildIntervalRow('Gear Oil', _gearKmController, _gearMonthsController),
                      _buildIntervalRow('General Service', _generalKmController, _generalMonthsController),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          );
        },
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
