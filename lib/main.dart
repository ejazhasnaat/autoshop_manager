// lib/main.dart
import 'dart:io' show Platform;
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/features/reminders/domain/reminder_service.dart';
import 'package:autoshop_manager/services/notification_service.dart';
import 'package:drift/drift.dart'
    show Value; // <-- ADDED: Import for using Value()
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/core/router.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final db = AppDatabase();
      final historyDao = ServiceHistoryDao(db);
      final preferenceRepository = PreferenceRepository();
      final preferences = await preferenceRepository.getPreferences();
      final reminderService = ReminderService(historyDao, preferences);
      final notificationService = NotificationService();

      await notificationService.init();

      final vehicles = await db.vehicleDao.getAllVehicles();

      for (var vehicle in vehicles) {
        final result = await reminderService.calculateNextReminder(vehicle);

        if (result != null) {
          // --- FIXED: Save the calculated reminder date back to the database ---
          final vehicleToUpdate = vehicle.copyWith(
            nextReminderDate: Value(result.date),
            nextReminderType: Value(result.type),
          );
          await db.vehicleDao.updateVehicle(vehicleToUpdate);
          // --- End of Fix ---

          // If a reminder is due within the next 7 days, show a notification
          if (result.date.isBefore(
            DateTime.now().add(const Duration(days: 7)),
          )) {
            final notificationId = vehicle.id + result.type.hashCode;

            await notificationService.showNotification(
              id: notificationId,
              title:
                  'Service Reminder: ${vehicle.make ?? ''} ${vehicle.model ?? ''}',
              body:
                  '${result.type} is due on ${result.date.toLocal().toString().split(' ')[0]}',
            );
          }
        }
      }
      return Future.value(true);
    } catch (err) {
      return Future.value(false);
    }
  });
}

// Global instance of the notification service
final NotificationService notificationService = NotificationService();
const reminderTask = "com.autoshop_manager.reminderCheck";

// --- Main Application Entry Point ---

Future<void> main() async {
  // It ensures that Flutter's engine is ready.
  WidgetsFlutterBinding.ensureInitialized();

  // --- App Initialization ---
  await notificationService.init();

  // Initialize Workmanager only on supported platforms (Android/iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false for production releases
    );
    await Workmanager().registerPeriodicTask(
      reminderTask,
      "reminderCheck",
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresCharging: false,
      ),
    );
    Workmanager().registerOneOffTask("1", "reminderCheckOneOff");
  }

  // It sets up Riverpod for state management.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = appRouter;

    return MaterialApp.router(
      routerConfig: router,
      title: 'Autoshop Manager',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
