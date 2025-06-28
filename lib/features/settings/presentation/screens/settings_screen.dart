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
  final List<String> _supportedCurrencies = const [
    'PKR',
    'USD',

    'EUR',
    'GBP',
    'JPY'
  ];

  String? _currentCurrency;
  // --- ADDED: State variable for the new auto-print setting ---
  bool? _currentAutoPrint;
  bool _isInitialDataLoaded = false;

  // --- ADDED: Handler to save the auto-print setting when changed ---
  void _onAutoPrintChanged(bool newValue, UserPreferences currentPrefs) async {
    setState(() {
      _currentAutoPrint = newValue;
    });

    final notifier = ref.read(settingsNotifierProvider.notifier);
    final newPrefs = currentPrefs.copyWith(autoPrintReceipt: newValue);
    final success = await notifier.savePreferences(newPrefs);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      ref.invalidate(userPreferencesStreamProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save settings. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Revert on failure
      setState(() {
        _currentAutoPrint = currentPrefs.autoPrintReceipt;
      });
    }
  }

  void _onCurrencyChanged(
      String? newValue, UserPreferences currentPrefs) async {
    if (newValue == null || newValue == _currentCurrency) {
      return;
    }

    setState(() {
      _currentCurrency = newValue;
    });

    final notifier = ref.read(settingsNotifierProvider.notifier);
    final newPrefs = currentPrefs.copyWith(defaultCurrency: newValue);

    final success = await notifier.savePreferences(newPrefs);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      ref.invalidate(userPreferencesStreamProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save settings. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _currentCurrency = currentPrefs.defaultCurrency;
      });
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
            // --- ADDED: Initialize the local state for the auto-print setting ---
            _currentAutoPrint = prefs.autoPrintReceipt;
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
                          items:
                              _supportedCurrencies.map((String currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            _onCurrencyChanged(newValue, prefs);
                          },
                        ),
                      ),
                      // --- ADDED: UI element for the new auto-print setting ---
                      SwitchListTile(
                        title: const Text('Auto-Print Receipt'),
                        subtitle: const Text(
                            'Automatically open the print dialog after completing a job.'),
                        value: _currentAutoPrint ?? false,
                        onChanged: (bool value) {
                          _onAutoPrintChanged(value, prefs);
                        },
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

