// lib/features/home/presentation/widgets/management_cards_row.dart
import 'package:autoshop_manager/core/providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: For optimal architecture, move each provider to its corresponding feature's provider file.

final customerCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final result = await db.select(db.customers).get();
  return result.length;
});

final vehicleMakeModelCountProvider = FutureProvider.autoDispose<(int, int)>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  final countExpression = db.vehicleModels.make.count();
  final totalModelsQuery = db.selectOnly(db.vehicleModels)..addColumns([countExpression]);
  
  final totalModels = await totalModelsQuery.map((row) => row.read(countExpression)).getSingleOrNull() ?? 0;

  final distinctMakesQuery = db.selectOnly(db.vehicleModels, distinct: true)
    ..addColumns([db.vehicleModels.make]);
  final distinctMakes = (await distinctMakesQuery.get()).length;

  return (distinctMakes, totalModels);
});


final inventoryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final result = await db.select(db.inventoryItems).get();
  return result.length;
});

final serviceCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final result = await db.select(db.services).get();
  return result.length;
});

final oilChangeIntervalProvider = Provider.autoDispose<AsyncValue<String>>((ref) {
  final userPrefsAsync = ref.watch(userPreferencesStreamProvider);
  return userPrefsAsync.whenData((prefs) {
    return '${prefs.engineOilIntervalKm} Km';
  });
});


class ManagementCardsRow extends ConsumerWidget {
  const ManagementCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerCount = ref.watch(customerCountProvider);
    final vehicleMakeModelCount = ref.watch(vehicleMakeModelCountProvider);
    final inventoryCount = ref.watch(inventoryCountProvider);
    final serviceCount = ref.watch(serviceCountProvider);
    final reminderInterval = ref.watch(oilChangeIntervalProvider);

    return Row(
      children: [
        Expanded(
          child: _ManagementCard(
            title: 'Customers',
            value: customerCount.when(data: (d) => d.toString(), error: (e,s) => '!', loading: () => '...'),
            description: 'View and manage customers.',
            icon: Icons.people_alt_outlined,
            iconColor: Colors.teal.shade600,
            onTap: () => context.go('/customers'),
            isLoading: customerCount.isLoading,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Vehicles',
            value: vehicleMakeModelCount.when(
              data: (counts) => '${counts.$1} / ${counts.$2}',
              error: (e,s) => '!',
              loading: () => '...',
            ),
            description: 'View and manage vehicles.',
            icon: Icons.directions_car_outlined,
            iconColor: Colors.indigo.shade600,
            onTap: () => context.go('/vehicle_models'),
            isLoading: vehicleMakeModelCount.isLoading,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Inventory',
            value: inventoryCount.when(data: (d) => d.toString(), error: (e,s) => '!', loading: () => '...'),
            description: 'Track parts and stock.',
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.brown.shade600,
            onTap: () => context.go('/inventory'),
            isLoading: inventoryCount.isLoading,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Repair Services',
            value: serviceCount.when(data: (d) => d.toString(), error: (e,s) => '!', loading: () => '...'),
            description: 'Configure repair services.',
            icon: Icons.build_circle_outlined,
            iconColor: Colors.pink.shade600,
            onTap: () => context.go('/services'),
            isLoading: serviceCount.isLoading,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Reminder Intervals',
            value: reminderInterval.when(data: (d) => d, error: (e,s) => '!', loading: () => '...'),
            description: 'Configure reminder intervals.',
            icon: Icons.alarm_on_outlined,
            iconColor: Colors.orange.shade700,
            onTap: () => context.push('/reminders/intervals'),
            isLoading: reminderInterval.isLoading,
            valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String title;
  final String? value;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLoading;
  final TextStyle? valueStyle;

  const _ManagementCard({
    required this.title,
    this.value,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isLoading = false,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  Icon(icon, color: iconColor),
                ],
              ),
              const SizedBox(height: 8),
              if (value != null)
                if (isLoading)
                  const SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                    ),
                  )
                else
                  Text(
                    value!, 
                    style: valueStyle ?? textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
              if (value != null)
                const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

