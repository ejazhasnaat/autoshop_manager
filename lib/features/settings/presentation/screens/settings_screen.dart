// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // List of supported currency symbols
  final List<String> _supportedCurrencies = const [
    'PKR',
    'USD',
    'EUR',
    'GBP',
    'JPY',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current currency symbol
    final currentCurrency = ref.watch(currentCurrencySymbolProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Settings', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      title: const Text('Default Currency'),
                      subtitle: DropdownButtonFormField<String>(
                        value: currentCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _supportedCurrencies.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            final success = await settingsNotifier
                                .updateDefaultCurrency(newValue);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Currency updated to $newValue!',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update currency.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    // Add more settings options here in the future
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
