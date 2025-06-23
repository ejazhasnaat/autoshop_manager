import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/core/providers.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  // This will be overridden in main.dart, but we keep a fallback.
  return ReminderRepository(ref.watch(appDatabaseProvider));
});

class ReminderRepository {
  final AppDatabase _db;
  ReminderRepository(this._db);

  // --- NEW: Seeding logic is now part of the repository ---
  Future<void> seedTemplatesFromJson({bool forceReset = false}) async {
    try {
      if (!forceReset) {
        final count = await (_db.select(_db.messageTemplates)).get().then((value) => value.length);
        if (count > 0) return; // Already seeded
      }

      final jsonString = await rootBundle.loadString('assets/reminder_templates.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final companions = jsonList.map((json) {
        return MessageTemplatesCompanion(
          templateType: Value(json['templateType']),
          title: Value(json['title']),
          content: Value(json['content']),
        );
      }).toList();

      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.messageTemplates, companions);
      });

      print('Successfully seeded/reset reminder templates from JSON.');

    } catch (e) {
      print('Error seeding templates from JSON: $e');
    }
  }

  Future<ShopSetting> getShopSettings() async {
    return (_db.select(_db.shopSettings)..where((s) => s.id.equals(1))).getSingle();
  }

  Future<List<Vehicle>> getUpcomingReminders({int days = 7}) async {
    final now = DateTime.now();
    final upcomingDate = now.add(Duration(days: days));
    return (_db.select(_db.vehicles)
          ..where((v) => v.isReminderActive.equals(true))
          ..where((v) => v.nextReminderDate.isNotNull())
          ..where((v) => v.nextReminderDate.isBetweenValues(now, upcomingDate))
          ..where(
            (v) =>
                v.reminderSnoozedUntil.isNull() |
                (v.reminderSnoozedUntil.isNotNull() &
                    v.reminderSnoozedUntil.isSmallerThanValue(now)),
          ))
        .get();
  }

  Future<bool> snoozeReminder(int vehicleId, DateTime untilDate) {
    final companion = VehiclesCompanion(reminderSnoozedUntil: Value(untilDate));
    return (_db.update(_db.vehicles)..where((v) => v.id.equals(vehicleId)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  Future<bool> stopReminder(int vehicleId) {
    final companion = VehiclesCompanion(isReminderActive: const Value(false));
    return (_db.update(_db.vehicles)..where((v) => v.id.equals(vehicleId)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  Future<List<MessageTemplate>> getMessageTemplates({String query = ''}) {
    final select = _db.select(_db.messageTemplates);
    if (query.isNotEmpty) {
      select.where((t) => t.title.like('%$query%') | t.content.like('%$query%'));
    }
    return select.get();
  }
  
  Future<bool> templateExists(String templateType) async {
    final existing = await (_db.select(_db.messageTemplates)
          ..where((t) => t.templateType.equals(templateType)))
        .getSingleOrNull();
    return existing != null;
  }

  Future<void> saveMessageTemplate(MessageTemplatesCompanion template) {
    return _db.into(_db.messageTemplates).insertOnConflictUpdate(template);
  }

  Future<bool> deleteMessageTemplate(String templateType) {
    return (_db.delete(_db.messageTemplates)
          ..where((t) => t.templateType.equals(templateType)))
        .go()
        .then((rows) => rows > 0);
  }
}
