// lib/features/settings/presentation/settings_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';

// This StreamProvider correctly opens a connection to the repository stream.
// It will now provide the full UserPreferences object, including service intervals.
final userPreferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  final preferenceRepository = ref.watch(preferenceRepositoryProvider);
  // The repository method was updated to get all preferences, so we use that now.
  // We'll convert the Future to a Stream for compatibility.
  return Stream.fromFuture(preferenceRepository.getPreferences());
});

// This provider correctly derives the currency symbol from the stream above.
// No changes are needed here.
final currentCurrencySymbolProvider = Provider<String>((ref) {
  final preferencesAsync = ref.watch(userPreferencesStreamProvider);

  return preferencesAsync.when(
    data: (prefs) => prefs.defaultCurrency,
    loading: () => 'PKR',
    error: (err, stack) {
      print('Error in currentCurrencySymbolProvider: $err');
      return 'PKR';
    },
  );
});

// This StateNotifierProvider exposes the "write" methods to the UI.
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier(ref.read(preferenceRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final PreferenceRepository _preferenceRepository;

  SettingsNotifier(this._preferenceRepository) : super(const AsyncData(null));

  /// Updates the user's default currency.
  Future<bool> updateDefaultCurrency(String currencySymbol) async {
    state = const AsyncLoading(); 
    try {
      // The repository now uses a unified save method, so we need to get current prefs first.
      final currentPrefs = await _preferenceRepository.getPreferences();
      final newPrefs = UserPreferences(
        defaultCurrency: currencySymbol,
        engineOilIntervalKm: currentPrefs.engineOilIntervalKm,
        engineOilIntervalMonths: currentPrefs.engineOilIntervalMonths,
        gearOilIntervalKm: currentPrefs.gearOilIntervalKm,
        gearOilIntervalMonths: currentPrefs.gearOilIntervalMonths,
        generalServiceIntervalKm: currentPrefs.generalServiceIntervalKm,
        generalServiceIntervalMonths: currentPrefs.generalServiceIntervalMonths
      );
      await _preferenceRepository.savePreferences(newPrefs);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  // --- NEWLY ADDED: Method to save all preference settings at once ---
  Future<bool> savePreferences(UserPreferences preferences) async {
    state = const AsyncLoading();
    try {
      await _preferenceRepository.savePreferences(preferences);
      state = const AsyncData(null);
      return true;
    } catch(e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
