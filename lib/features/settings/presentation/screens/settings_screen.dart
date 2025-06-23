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
  
  // Controllers for intervals are removed from here

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    ref.read(preferenceRepositoryProvider).getPreferences().then((prefs) {
      if (mounted) {
        setState(() {
          _currentCurrency = prefs.defaultCurrency;
        });
      }
    });
  }

  @override
  void dispose() {
    // Disposing controllers is removed from here
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      // Need to read the current prefs to avoid overwriting interval settings
      final currentPrefs = await ref.read(preferenceRepositoryProvider).getPreferences();
      final newPrefs = currentPrefs.copyWith(
        defaultCurrency: _currentCurrency ?? 'PKR',
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
