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

  String? _currentCurrency;
  bool _isInitialDataLoaded = false;
  bool _didSettingsChange = false; // Flag to check if a save is needed.

  @override
  void dispose() {
    if (_didSettingsChange) {
      _saveSettings();
    }
    super.dispose();
  }

  void _saveSettings() async {
    // This method is now called from dispose, so we don't use form validation or show a snackbar.
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final currentPrefs = await ref.read(preferenceRepositoryProvider).getPreferences();
    
    final newPrefs = currentPrefs.copyWith(
      defaultCurrency: _currentCurrency ?? 'PKR',
    );

    final success = await notifier.savePreferences(newPrefs);

    if (success) {
      // Invalidate the provider to ensure the rest of the app gets the fresh settings.
      ref.invalidate(userPreferencesStreamProvider);
    } else {
      print('Failed to auto-save settings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userPreferencesStreamProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'App Settings', showCloseButton: true),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err')),
        data: (prefs) {
          if (!_isInitialDataLoaded) {
            _currentCurrency = prefs.defaultCurrency;
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
                            return DropdownMenuItem<String>(value: currency, child: Text(currency));
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentCurrency = newValue;
                                _didSettingsChange = true;
                              });
                            }
                          },
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
