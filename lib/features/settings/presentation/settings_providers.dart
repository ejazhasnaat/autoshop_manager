// lib/features/settings/presentation/settings_providers.dart
import 'dart:convert';
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/features/settings/domain/models/country.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/countries.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => Country.fromJson(json)).toList();
});


final userPreferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  final preferenceRepository = ref.watch(preferenceRepositoryProvider);
  return Stream.fromFuture(preferenceRepository.getPreferences());
});

// --- FIX: Re-added the provider for just the currency symbol ---
final currentCurrencySymbolProvider = Provider<String>((ref) {
  final userPrefsAsync = ref.watch(userPreferencesStreamProvider);
  final countriesAsync = ref.watch(countriesProvider);

  const defaultSymbol = '\$';

  if (userPrefsAsync.hasValue && countriesAsync.hasValue) {
    final prefs = userPrefsAsync.value!;
    final countries = countriesAsync.value!;
    
    final selectedCountry = countries.firstWhere(
      (c) => c.currencyCode == prefs.defaultCurrency,
      orElse: () => countries.firstWhere((c) => c.currencyCode == 'USD', orElse: () => countries.first),
    );

    return selectedCountry.currencySymbol;
  }
  
  return defaultSymbol;
});

// This provider now depends on the symbol provider for simplicity and consistency.
final currencyFormatterProvider = Provider<NumberFormat>((ref) {
  final symbol = ref.watch(currentCurrencySymbolProvider);
  
  return NumberFormat.currency(
    locale: 'en_US', // Ensures consistent decimal/grouping separators
    symbol: '$symbol ', // Uses the symbol from the provider above
  );
});


final shopSettingsProvider = FutureProvider<ShopSetting>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.shopSettings)..where((tbl) => tbl.id.equals(1)))
      .getSingle();
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  final preferenceRepository = ref.watch(preferenceRepositoryProvider);
  return SettingsNotifier(preferenceRepository, ref);
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final PreferenceRepository _preferenceRepository;
  final Ref _ref;

  SettingsNotifier(this._preferenceRepository, this._ref)
      : super(const AsyncData(null));

  Future<bool> savePreferences(UserPreferences preferences) async {
    state = const AsyncLoading();
    try {
      await _preferenceRepository.savePreferences(preferences);
      _ref.invalidate(userPreferencesStreamProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final workshopSettingsNotifierProvider =
    StateNotifierProvider<WorkshopSettingsNotifier, AsyncValue<void>>((ref) {
  return WorkshopSettingsNotifier(ref.watch(appDatabaseProvider), ref);
});

class WorkshopSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  WorkshopSettingsNotifier(this._db, this._ref) : super(const AsyncData(null));

  Future<bool> updateShopSettings(ShopSettingsCompanion settings) async {
    state = const AsyncLoading();
    try {
      await (_db.update(_db.shopSettings)..where((tbl) => tbl.id.equals(1)))
          .write(settings);
      _ref.invalidate(shopSettingsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

