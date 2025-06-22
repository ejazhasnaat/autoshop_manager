// lib/data/repositories/preference_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for storing values in shared_preferences
const String _kCurrency = 'defaultCurrency';
const String _kEngineKm = 'engineOilIntervalKm';
const String _kEngineMonths = 'engineOilIntervalMonths';
const String _kGearKm = 'gearOilIntervalKm';
const String _kGearMonths = 'gearOilIntervalMonths';
const String _kGeneralKm = 'generalServiceIntervalKm';
const String _kGeneralMonths = 'generalServiceIntervalMonths';

// Data class to hold all user preferences
class UserPreferences {
  final String defaultCurrency;
  final int engineOilIntervalKm;
  final int engineOilIntervalMonths;
  final int gearOilIntervalKm;
  final int gearOilIntervalMonths;
  final int generalServiceIntervalKm;
  final int generalServiceIntervalMonths;

  UserPreferences({
    this.defaultCurrency = 'PKR',
    this.engineOilIntervalKm = 5000,
    this.engineOilIntervalMonths = 6,
    this.gearOilIntervalKm = 40000,
    this.gearOilIntervalMonths = 24,
    this.generalServiceIntervalKm = 10000,
    this.generalServiceIntervalMonths = 12,
  });
}

// Provider for the repository
final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository();
});

// This repository now uses SharedPreferences for local, persistent storage.
class PreferenceRepository {
  // Method to get all preferences, providing defaults if they don't exist.
  Future<UserPreferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences(
      defaultCurrency: prefs.getString(_kCurrency) ?? 'PKR',
      engineOilIntervalKm: prefs.getInt(_kEngineKm) ?? 5000,
      engineOilIntervalMonths: prefs.getInt(_kEngineMonths) ?? 6,
      gearOilIntervalKm: prefs.getInt(_kGearKm) ?? 40000,
      gearOilIntervalMonths: prefs.getInt(_kGearMonths) ?? 24,
      generalServiceIntervalKm: prefs.getInt(_kGeneralKm) ?? 10000,
      generalServiceIntervalMonths: prefs.getInt(_kGeneralMonths) ?? 12,
    );
  }

  // Method to save all preferences.
  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, preferences.defaultCurrency);
    await prefs.setInt(_kEngineKm, preferences.engineOilIntervalKm);
    await prefs.setInt(_kEngineMonths, preferences.engineOilIntervalMonths);
    await prefs.setInt(_kGearKm, preferences.gearOilIntervalKm);
    await prefs.setInt(_kGearMonths, preferences.gearOilIntervalMonths);
    await prefs.setInt(_kGeneralKm, preferences.generalServiceIntervalKm);
    await prefs.setInt(_kGeneralMonths, preferences.generalServiceIntervalMonths);
  }

  // --- Methods for compatibility with your existing CurrencyProvider ---
  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrency) ?? 'PKR';
  }

  Future<void> saveCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, currencyCode);
  }
}
