// lib/features/settings/domain/models/country.dart

import 'package:flutter/foundation.dart';

@immutable
class Country {
  final String name;
  final String currencyName;
  final String currencyCode;
  final String currencySymbol;
  final String flag;

  const Country({
    required this.name,
    required this.currencyName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.flag,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String,
      currencyName: json['currencyName'] as String,
      currencyCode: json['currencyCode'] as String,
      currencySymbol: json['currencySymbol'] as String,
      flag: json['flag'] as String,
    );
  }
}

