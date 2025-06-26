// lib/features/settings/presentation/settings_providers.dart

import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';

final userPreferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  final preferenceRepository = ref.watch(preferenceRepositoryProvider);
  return Stream.fromFuture(preferenceRepository.getPreferences());
});

// This provider correctly derives the currency symbol from the stream above.
final currentCurrencySymbolProvider = Provider<String>((ref) {
  final preferencesAsync = ref.watch(userPreferencesStreamProvider);

  return preferencesAsync.when(
    data: (prefs) => prefs.defaultCurrency,
    loading: () => 'PKR', // Default value while loading
    error: (err, stack) {
      print('Error in currentCurrencySymbolProvider: $err');
      return 'PKR'; // Fallback value on error
    },
  );
});

// --- NEW: Provider to fetch the single ShopSetting entry ---
final shopSettingsProvider = FutureProvider<ShopSetting>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Assuming ShopSetting has a single entry with id = 1
  return (db.select(db.shopSettings)..where((tbl) => tbl.id.equals(1))).getSingle();
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier(ref.read(preferenceRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final PreferenceRepository _preferenceRepository;

  SettingsNotifier(this._preferenceRepository) : super(const AsyncData(null));

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
