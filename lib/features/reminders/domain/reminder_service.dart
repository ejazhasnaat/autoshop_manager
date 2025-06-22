// lib/features/reminders/domain/reminder_service.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';

class ReminderResult {
  final DateTime date;
  final String type;
  ReminderResult(this.date, this.type);
}

class ReminderService {
  final ServiceHistoryDao _historyDao;
  final UserPreferences _preferences;

  ReminderService(this._historyDao, this._preferences);
  
  // --- NEW: Dynamic average mileage calculation ---
  Future<double> _getAverageDailyMileage(int vehicleId) async {
    final history = await _historyDao.getHistoryForVehicle(vehicleId);
    if (history.length < 2) {
      return 30.0; // Return a default if not enough history
    }
    
    final firstRecord = history.first;
    final lastRecord = history.last;

    final mileageDifference = lastRecord.mileage - firstRecord.mileage;
    final daysDifference = lastRecord.serviceDate.difference(firstRecord.serviceDate).inDays;

    if (daysDifference <= 0 || mileageDifference <= 0) {
      return 30.0; // Avoid division by zero or nonsensical data
    }

    return mileageDifference / daysDifference;
  }

  // --- UPDATED: Now uses dynamic data and configurable settings ---
  Future<ReminderResult?> calculateNextReminder(Vehicle vehicle) async {
    final List<ReminderResult> potentialReminders = [];
    final averageDailyMileage = await _getAverageDailyMileage(vehicle.id);

    // --- Engine Oil Change ---
    if (vehicle.lastEngineOilChangeDate != null) {
      final timeBasedReminder = vehicle.lastEngineOilChangeDate!.add(Duration(days: _preferences.engineOilIntervalMonths * 30));
      potentialReminders.add(ReminderResult(timeBasedReminder, 'Engine Oil Change'));

      if (vehicle.lastEngineOilChangeMileage != null && vehicle.currentMileage != null) {
        final mileageLeft = _preferences.engineOilIntervalKm - (vehicle.currentMileage! - vehicle.lastEngineOilChangeMileage!);
        if (mileageLeft > 0 && averageDailyMileage > 0) {
          final daysToMileageReminder = (mileageLeft / averageDailyMileage).round();
          potentialReminders.add(ReminderResult(DateTime.now().add(Duration(days: daysToMileageReminder)), 'Engine Oil Change'));
        }
      }
    }
    
    // --- Gear Oil Change ---
    if (vehicle.lastGearOilChangeDate != null) {
        final timeBasedReminder = vehicle.lastGearOilChangeDate!.add(Duration(days: _preferences.gearOilIntervalMonths * 30));
        potentialReminders.add(ReminderResult(timeBasedReminder, 'Gear Oil Change'));

        if (vehicle.lastGearOilChangeMileage != null && vehicle.currentMileage != null) {
            final mileageLeft = _preferences.gearOilIntervalKm - (vehicle.currentMileage! - vehicle.lastGearOilChangeMileage!);
            if (mileageLeft > 0 && averageDailyMileage > 0) {
                final daysToMileageReminder = (mileageLeft / averageDailyMileage).round();
                potentialReminders.add(ReminderResult(DateTime.now().add(Duration(days: daysToMileageReminder)), 'Gear Oil Change'));
            }
        }
    }

    // --- General Service ---
    if (vehicle.lastGeneralServiceDate != null) {
        final timeBasedReminder = vehicle.lastGeneralServiceDate!.add(Duration(days: _preferences.generalServiceIntervalMonths * 30));
        potentialReminders.add(ReminderResult(timeBasedReminder, 'General Service'));

        if (vehicle.lastGeneralServiceMileage != null && vehicle.currentMileage != null) {
            final mileageLeft = _preferences.generalServiceIntervalKm - (vehicle.currentMileage! - vehicle.lastGeneralServiceMileage!);
            if (mileageLeft > 0 && averageDailyMileage > 0) {
                final daysToMileageReminder = (mileageLeft / averageDailyMileage).round();
                potentialReminders.add(ReminderResult(DateTime.now().add(Duration(days: daysToMileageReminder)), 'General Service'));
            }
        }
    }

    if (potentialReminders.isEmpty) return null;
    
    potentialReminders.sort((a, b) => a.date.compareTo(b.date));
    return potentialReminders.first;
  }
}
