// lib/data/repositories/preference_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ADDED: Key for the new auto-print setting ---
const String _kAutoPrint = 'autoPrintReceipt';
const String _kKeepMeLoggedIn = 'keepMeLoggedIn';
const String _kSetupComplete = 'setupComplete';
const String _kAutoLoginUser = 'autoLoginUsername';
const String _kCurrency = 'defaultCurrency';
const String _kEngineKm = 'engineOilIntervalKm';
const String _kEngineMonths = 'engineOilIntervalMonths';
const String _kGearKm = 'gearOilIntervalKm';
const String _kGearMonths = 'gearOilIntervalMonths';
const String _kGeneralKm = 'generalServiceIntervalKm';
const String _kGeneralMonths = 'generalServiceIntervalMonths';
const String _kLocalLanguage = 'localLanguage';

class UserPreferences {
  final String defaultCurrency;
  final int engineOilIntervalKm;
  final int engineOilIntervalMonths;
  final int gearOilIntervalKm;
  final int gearOilIntervalMonths;
  final int generalServiceIntervalKm;
  final int generalServiceIntervalMonths;
  final String localLanguage;
  // --- ADDED: New property for auto-printing receipts ---
  final bool autoPrintReceipt;

  UserPreferences({
    this.defaultCurrency = 'PKR',
    this.engineOilIntervalKm = 5000,
    this.engineOilIntervalMonths = 6,
    this.gearOilIntervalKm = 40000,
    this.gearOilIntervalMonths = 24,
    this.generalServiceIntervalKm = 10000,
    this.generalServiceIntervalMonths = 12,
    this.localLanguage = 'English',
    // --- ADDED: Default value for the new setting ---
    this.autoPrintReceipt = false,
  });

  UserPreferences copyWith({
    String? defaultCurrency,
    int? engineOilIntervalKm,
    int? engineOilIntervalMonths,
    int? gearOilIntervalKm,
    int? gearOilIntervalMonths,
    int? generalServiceIntervalKm,
    int? generalServiceIntervalMonths,
    String? localLanguage,
    // --- ADDED: New setting to the copyWith method ---
    bool? autoPrintReceipt,
  }) {
    return UserPreferences(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      engineOilIntervalKm: engineOilIntervalKm ?? this.engineOilIntervalKm,
      engineOilIntervalMonths:
          engineOilIntervalMonths ?? this.engineOilIntervalMonths,
      gearOilIntervalKm: gearOilIntervalKm ?? this.gearOilIntervalKm,
      gearOilIntervalMonths:
          gearOilIntervalMonths ?? this.gearOilIntervalMonths,
      generalServiceIntervalKm:
          generalServiceIntervalKm ?? this.generalServiceIntervalKm,
      generalServiceIntervalMonths:
          generalServiceIntervalMonths ?? this.generalServiceIntervalMonths,
      localLanguage: localLanguage ?? this.localLanguage,
      // --- ADDED: Logic to handle copying the new setting ---
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    );
  }
}

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository();
});

class PreferenceRepository {
  Future<bool> getKeepMeLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kKeepMeLoggedIn) ?? false;
  }

  Future<void> saveKeepMeLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeepMeLoggedIn, value);
  }

  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSetupComplete) ?? false;
  }

  Future<void> markSetupAsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSetupComplete, true);
  }

  Future<void> setAutoLoginUser(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username != null) {
      await prefs.setString(_kAutoLoginUser, username);
    } else {
      await prefs.remove(_kAutoLoginUser);
    }
  }

  Future<String?> getAutoLoginUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAutoLoginUser);
  }

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
      localLanguage: prefs.getString(_kLocalLanguage) ?? 'English',
      // --- ADDED: Loading the new setting from shared preferences ---
      autoPrintReceipt: prefs.getBool(_kAutoPrint) ?? false,
    );
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, preferences.defaultCurrency);
    await prefs.setInt(_kEngineKm, preferences.engineOilIntervalKm);
    await prefs.setInt(_kEngineMonths, preferences.engineOilIntervalMonths);
    await prefs.setInt(_kGearKm, preferences.gearOilIntervalKm);
    await prefs.setInt(_kGearMonths, preferences.gearOilIntervalMonths);
    await prefs.setInt(_kGeneralKm, preferences.generalServiceIntervalKm);
    await prefs.setInt(
        _kGeneralMonths, preferences.generalServiceIntervalMonths);
    await prefs.setString(_kLocalLanguage, preferences.localLanguage);
    // --- ADDED: Saving the new setting to shared preferences ---
    await prefs.setBool(_kAutoPrint, preferences.autoPrintReceipt);
  }
}

