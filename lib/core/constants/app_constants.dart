// lib/core/constants/app_constants.dart
// This file defines app-wide constants.

class AppConstants {
  static const String appName = 'Autoshop Manager';
  static const String defaultAdminUsername = 'admin';
  static const String defaultAdminPin =
      'admin123'; // IMPORTANT: Use a stronger, dynamically set PIN in a real production app!

  // Inventory thresholds
  static const int lowStockThreshold =
      5; // Example threshold for inventory alerts
}
