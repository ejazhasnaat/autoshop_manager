// lib/features/settings/presentation/providers/currency_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/features/settings/domain/models/currency.dart';

class CurrencyProvider with ChangeNotifier {
  final PreferenceRepository _preferenceRepository;
  late Currency _selectedCurrency;
  bool _isLoading = true;

  CurrencyProvider(this._preferenceRepository) {
    // Set a default to prevent null issues before loading is complete.
    _selectedCurrency = supportedCurrencies.first;
    _loadCurrency();
  }

  // Getters for the UI to consume state
  Currency get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;

  // --- Core Logic ---

  /// Loads the saved currency from the repository on initialization.
  Future<void> _loadCurrency() async {
    final currencyCode = await _preferenceRepository.getCurrency();
    _selectedCurrency = supportedCurrencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => supportedCurrencies.first, // Fallback to PKR
    );
    _isLoading = false;
    notifyListeners(); // Notify listeners that loading is complete
  }

  /// Updates the currency, saves it, and notifies listeners.
  Future<void> updateCurrency(String newCurrencyCode) async {
    _selectedCurrency = supportedCurrencies.firstWhere(
      (c) => c.code == newCurrencyCode,
      orElse: () => supportedCurrencies.first,
    );
    await _preferenceRepository.saveCurrency(newCurrencyCode);
    notifyListeners();
  }

  /// Formats a numeric amount into a currency string based on the selected currency.
  String format(double amount) {
    // We use a fixed locale like 'en_US' to ensure consistent number formatting
    // (e.g., dots for decimals), but we provide our own symbol.
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${_selectedCurrency.symbol} ', // Note the space for padding
    );
    return format.format(amount);
  }
}
