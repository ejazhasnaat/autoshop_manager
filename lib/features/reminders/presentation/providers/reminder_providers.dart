import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/features/reminders/data/reminder_repository.dart';

final shopSettingsProvider = FutureProvider.autoDispose<ShopSetting>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getShopSettings();
});

final templateSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final upcomingRemindersProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getUpcomingReminders();
});

final messageTemplatesProvider =
    FutureProvider.autoDispose<List<MessageTemplate>>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  final query = ref.watch(templateSearchQueryProvider);
  return repository.getMessageTemplates(query: query);
});

final remindersNotifierProvider =
    StateNotifierProvider.autoDispose<RemindersNotifier, AsyncValue<void>>(
        (ref) {
  return RemindersNotifier(ref);
});

class RemindersNotifier extends StateNotifier<AsyncValue<void>> {
  RemindersNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> resetDefaultTemplates() async {
    state = const AsyncLoading();
    try {
      await _ref.read(reminderRepositoryProvider).seedTemplatesFromJson(forceReset: true);
      _ref.invalidate(messageTemplatesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<void> snoozeReminder(int vehicleId, DateTime untilDate) async {
    state = const AsyncLoading();
    await _ref.read(reminderRepositoryProvider).snoozeReminder(vehicleId, untilDate);
    _ref.invalidate(upcomingRemindersProvider);
    state = const AsyncData(null);
  }

  Future<void> stopReminder(int vehicleId) async {
    state = const AsyncLoading();
    await _ref.read(reminderRepositoryProvider).stopReminder(vehicleId);
    _ref.invalidate(upcomingRemindersProvider);
    state = const AsyncData(null);
  }

  Future<void> saveTemplate(MessageTemplatesCompanion template) async {
    state = const AsyncLoading();
    await _ref.read(reminderRepositoryProvider).saveMessageTemplate(template);
    _ref.invalidate(messageTemplatesProvider);
    state = const AsyncData(null);
  }

  Future<void> deleteTemplate(String templateType) async {
    state = const AsyncLoading();
    await _ref.read(reminderRepositoryProvider).deleteMessageTemplate(templateType);
    _ref.invalidate(messageTemplatesProvider);
    state = const AsyncData(null);
  }
}
