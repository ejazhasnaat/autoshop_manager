// lib/data/repositories/preference_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ADDED: Keys for the new history retention settings ---
const String _kHistoryRetentionPeriod = 'historyRetentionPeriod';
const String _kHistoryRetentionUnit = 'historyRetentionUnit';
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
const String _kAutoPrint = 'autoPrintReceipt';


class UserPreferences {
  final String defaultCurrency;
  final int engineOilIntervalKm;
  final int engineOilIntervalMonths;
  final int gearOilIntervalKm;
  final int gearOilIntervalMonths;
  final int generalServiceIntervalKm;
  final int generalServiceIntervalMonths;
  final String localLanguage;
  final bool autoPrintReceipt;
  // --- ADDED: New properties for history retention ---
  final int historyRetentionPeriod;
  final String historyRetentionUnit; // e.g., 'Days', 'Months', 'Years'

  UserPreferences({
    this.defaultCurrency = 'PKR',
    this.engineOilIntervalKm = 5000,
    this.engineOilIntervalMonths = 6,
    this.gearOilIntervalKm = 40000,
    this.gearOilIntervalMonths = 24,
    this.generalServiceIntervalKm = 10000,
    this.generalServiceIntervalMonths = 12,
    this.localLanguage = 'English',
    this.autoPrintReceipt = false,
    // --- ADDED: Default values for the new settings (e.g., 1 Year) ---
    this.historyRetentionPeriod = 1,
    this.historyRetentionUnit = 'Years',
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
    bool? autoPrintReceipt,
    // --- ADDED: New settings to the copyWith method ---
    int? historyRetentionPeriod,
    String? historyRetentionUnit,
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
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      // --- ADDED: Logic to handle copying the new settings ---
      historyRetentionPeriod: historyRetentionPeriod ?? this.historyRetentionPeriod,
      historyRetentionUnit: historyRetentionUnit ?? this.historyRetentionUnit,
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
      autoPrintReceipt: prefs.getBool(_kAutoPrint) ?? false,
      // --- ADDED: Loading the new settings from shared preferences ---
      historyRetentionPeriod: prefs.getInt(_kHistoryRetentionPeriod) ?? 1,
      historyRetentionUnit: prefs.getString(_kHistoryRetentionUnit) ?? 'Years',
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
    await prefs.setBool(_kAutoPrint, preferences.autoPrintReceipt);
    // --- ADDED: Saving the new settings to shared preferences ---
    await prefs.setInt(_kHistoryRetentionPeriod, preferences.historyRetentionPeriod);
    await prefs.setString(_kHistoryRetentionUnit, preferences.historyRetentionUnit);
  }
}

