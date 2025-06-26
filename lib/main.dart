// lib/main.dart
import 'dart:io' show Platform;
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/core/router.dart';
import 'package:autoshop_manager/core/setup_providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/data/repositories/service_repository.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/features/reminders/data/reminder_repository.dart';
import 'package:autoshop_manager/features/reminders/domain/reminder_service.dart';
import 'package:autoshop_manager/services/notification_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase();
    try {
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
          final vehicleToUpdate = vehicle.copyWith(
            nextReminderDate: Value(result.date),
            nextReminderType: Value(result.type),
          );
          await db.vehicleDao.updateVehicle(vehicleToUpdate);
          if (result.date.isBefore(DateTime.now().add(const Duration(days: 7)))) {
            final notificationId = vehicle.id + result.type.hashCode;
            await notificationService.showNotification(
              id: notificationId,
              title: 'Service Reminder: ${vehicle.make ?? ''} ${vehicle.model ?? ''}',
              body: '${result.type} is due on ${result.date.toLocal().toString().split(' ')[0]}',
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

final NotificationService notificationService = NotificationService();
const reminderTask = "com.autoshop_manager.reminderCheck";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = PreferenceRepository();
  final isSetupComplete = await prefs.isSetupComplete();
  
  // FINAL FIX: We restore the original ProviderContainer approach
  // which works for data loading, and fix the navigation issue within it.
  final container = ProviderContainer(
    overrides: [
      // We no longer need to override appDatabaseProvider because its
      // default implementation is now correct.
      setupCompleteProvider.overrideWith((ref) => isSetupComplete),
    ],
  );

  if (isSetupComplete) {
    // FINAL FIX: We `await` the auto-login check BEFORE running the app.
    // This solves the navigation race condition permanently.
    await container.read(authNotifierProvider.notifier).tryAutoLogin();
  } else {
    await container.read(reminderRepositoryProvider).seedTemplatesFromJson();
    await container.read(serviceRepositoryProvider).seedServicesFromJson();
    await prefs.markSetupAsComplete();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );

  // Background tasks can be initialized after the app starts.
  await notificationService.init();
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      reminderTask,
      "reminderCheck",
      frequency: const Duration(hours: 12),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The auto-login is no longer needed here.
    final router = ref.watch(routerProvider);

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
      debugShowCheckedModeBanner: false,
    );
  }
}
