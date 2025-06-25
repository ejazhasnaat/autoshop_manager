// lib/features/settings/presentation/settings_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';

final userPreferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  final preferenceRepository = ref.watch(preferenceRepositoryProvider);
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
      final currentPrefs = await _preferenceRepository.getPreferences();
      final newPrefs = UserPreferences(
        defaultCurrency: currencySymbol,
        engineOilIntervalKm: currentPrefs.engineOilIntervalKm,
        engineOilIntervalMonths: currentPrefs.engineOilIntervalMonths,
        gearOilIntervalKm: currentPrefs.gearOilIntervalKm,
        gearOilIntervalMonths: currentPrefs.gearOilIntervalMonths,
        generalServiceIntervalKm: currentPrefs.generalServiceIntervalKm,
        generalServiceIntervalMonths: currentPrefs.generalServiceIntervalMonths,
        // UPDATE: Preserve the existing localLanguage when updating currency.
        localLanguage: currentPrefs.localLanguage
      );
      await _preferenceRepository.savePreferences(newPrefs);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  // This method correctly saves the full preferences object.
  // No changes are needed here.
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
