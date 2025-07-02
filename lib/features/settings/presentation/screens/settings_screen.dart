// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // --- ADDED: Controller for retention period input ---
  late TextEditingController _retentionPeriodController;

  String? _currentCurrency;
  bool? _currentAutoPrint;
  // --- ADDED: State variables for new data retention settings ---
  int? _historyRetentionPeriod;
  String? _historyRetentionUnit;

  bool _isInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _retentionPeriodController = TextEditingController();
  }
  
  @override
  void dispose() {
    _retentionPeriodController.dispose();
    super.dispose();
  }

  void _onAutoPrintChanged(bool newValue, UserPreferences currentPrefs) async {
    setState(() => _currentAutoPrint = newValue);
    _savePreferences(currentPrefs.copyWith(autoPrintReceipt: newValue));
  }
  
  void _onCurrencyChanged(String? newValue, UserPreferences currentPrefs) async {
    if (newValue == null || newValue == _currentCurrency) return;
    setState(() => _currentCurrency = newValue);
    _savePreferences(currentPrefs.copyWith(defaultCurrency: newValue));
  }
  
  // --- ADDED: Handler for saving data retention settings ---
  void _onRetentionChanged(UserPreferences currentPrefs) {
     final newPeriod = int.tryParse(_retentionPeriodController.text) ?? 1;
     final newUnit = _historyRetentionUnit ?? 'Years';

     setState(() {
       _historyRetentionPeriod = newPeriod;
       // No need to set state for _historyRetentionUnit as it's already handled by its Dropdown
     });

     _savePreferences(currentPrefs.copyWith(
       historyRetentionPeriod: newPeriod,
       historyRetentionUnit: newUnit,
     ));
  }

  // --- ADDED: A single, robust save method ---
  Future<void> _savePreferences(UserPreferences newPrefs) async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final success = await notifier.savePreferences(newPrefs);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Settings saved successfully.' : 'Failed to save settings.'),
        backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );

    if (success) {
      ref.invalidate(userPreferencesStreamProvider);
    } else {
      // If save fails, refresh UI from the old state to prevent inconsistency
      setState(() => _isInitialDataLoaded = false); 
    }
  }


  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userPreferencesStreamProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'App Settings', showCloseButton: true),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading settings: $err')),
        data: (prefs) {
          if (!_isInitialDataLoaded) {
            _currentCurrency = prefs.defaultCurrency;
            _currentAutoPrint = prefs.autoPrintReceipt;
            // --- ADDED: Initialize state for data retention settings ---
            _historyRetentionPeriod = prefs.historyRetentionPeriod;
            _historyRetentionUnit = prefs.historyRetentionUnit;
            _retentionPeriodController.text = _historyRetentionPeriod.toString();
            _isInitialDataLoaded = true;
          }

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
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (val) => _onCurrencyChanged(val, prefs),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Auto-Print Receipt'),
                        subtitle: const Text(
                            'Open print dialog after completing a job.'),
                        value: _currentAutoPrint ?? false,
                        onChanged: (val) => _onAutoPrintChanged(val, prefs),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // --- ADDED: New card for data management settings ---
                  _buildSettingsCard(
                    context,
                    title: 'Data Management',
                    children: [
                      ListTile(
                        title: const Text('Completed Job History'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Text('Keep records for: '),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _retentionPeriodController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  onEditingComplete: () => _onRetentionChanged(prefs),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _historyRetentionUnit,
                                  items: ['Days', 'Months', 'Years']
                                      .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    if(newValue != null) {
                                      setState(() => _historyRetentionUnit = newValue);
                                      _onRetentionChanged(prefs);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

