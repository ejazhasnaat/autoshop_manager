import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/reminders/data/reminder_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to get the current workshop settings
final workshopSettingsProvider = FutureProvider.autoDispose<ShopSetting>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getShopSettings();
});

// Notifier for handling settings-related actions
final workshopSettingsNotifierProvider =
    StateNotifierProvider.autoDispose<WorkshopSettingsNotifier, AsyncValue<void>>(
        (ref) {
  return WorkshopSettingsNotifier(ref);
});

class WorkshopSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  WorkshopSettingsNotifier(this._ref) : super(const AsyncData(null));

  // Method to update the workshop settings
  Future<bool> updateShopSettings(ShopSettingsCompanion settings) async {
    state = const AsyncLoading();
    try {
      await _ref.read(reminderRepositoryProvider).updateShopSettings(settings);
      _ref.invalidate(workshopSettingsProvider); // Refresh the provider
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
