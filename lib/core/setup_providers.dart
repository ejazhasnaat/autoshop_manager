import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider will hold the live status of the initial setup.
// The router will watch it to decide where to navigate.
final setupCompleteProvider = StateProvider<bool>((ref) {
  // It's initialized with a default value of false.
  // The true initial value will be loaded from storage and provided in main.dart.
  return false;
});
