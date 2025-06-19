// lib/features/settings/presentation/settings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart'; // Import the new repository

// StreamProvider for the current user's preferences (including currency)
final userPreferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  return ref.read(preferenceRepositoryProvider).getUserPreferencesStream();
});

// Provider for the currently selected currency symbol
final currentCurrencySymbolProvider = Provider<String>((ref) {
  // Watch the user preferences stream
  final preferencesAsync = ref.watch(userPreferencesStreamProvider);

  // Return the default currency from preferences, or a fallback 'PKR' if loading/error
  return preferencesAsync.when(
    data: (prefs) => prefs.defaultCurrency,
    loading: () => 'PKR', // Default currency while loading
    error: (err, stack) {
      print('Error watching currency: $err');
      return 'PKR'; // Fallback on error
    },
  );
});

// StateNotifier to manage updating settings
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, void>((
  ref,
) {
  return SettingsNotifier(ref.read(preferenceRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<void> {
  final PreferenceRepository _preferenceRepository;

  SettingsNotifier(this._preferenceRepository) : super(null);

  Future<bool> updateDefaultCurrency(String currencySymbol) async {
    final success = await _preferenceRepository.updateDefaultCurrency(
      currencySymbol,
    );
    if (success) {
      // Invalidate the stream provider to trigger a re-fetch and update all watchers
      // This is crucial for UI elements to react to the currency change.
      _preferenceRepository
          .getUserPreferencesStream(); // Calling it will trigger a re-fetch implicitly via the stream
    }
    return success;
  }
}
