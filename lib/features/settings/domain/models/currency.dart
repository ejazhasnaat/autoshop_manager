// lib/features/settings/domain/models/currency.dart

import 'package:flutter/foundation.dart';

@immutable
class Currency {
  final String code; // e.g., 'PKR'
  final String name; // e.g., 'Pakistani Rupee'
  final String symbol; // e.g., 'Rs'

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  // Override equals and hashCode to allow for object comparison in DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// This list acts as our business rule, defining all currencies supported by the app.
final List<Currency> supportedCurrencies = [
  const Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs'),
  const Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
  const Currency(code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
  const Currency(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR'),
  const Currency(code: 'EUR', name: 'Euro', symbol: '€'),
];
