// lib/features/vehicle/presentation/screens/vehicle_history_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// --- ADDED: Import for core providers like appDatabaseProvider ---
import 'package:autoshop_manager/core/providers.dart';

// This new provider will fetch the entire history for a specific vehicle
final vehicleHistoryProvider = StreamProvider.autoDispose.family<List<RepairJobWithDetails>, int>((ref, vehicleId) {
  final db = ref.watch(appDatabaseProvider);
  return db.repairJobDao.watchAllJobsForVehicle(vehicleId);
});

class VehicleHistoryScreen extends ConsumerWidget {
  final int vehicleId;

  const VehicleHistoryScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vehicleHistoryProvider(vehicleId));
    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: vehicleAsync.when(
          data: (v) => Text('History for ${v?.make} ${v?.model}'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Vehicle History'),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share), tooltip: 'Share History'),
          IconButton(onPressed: () {}, icon: const Icon(Icons.print), tooltip: 'Print History'),
        ],
      ),
      body: historyAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No service history found for this vehicle.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final jobDetails = jobs[index];
              return _HistoryJobCard(jobDetails: jobDetails);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}

class _HistoryJobCard extends ConsumerWidget {
  final RepairJobWithDetails jobDetails;

  const _HistoryJobCard({required this.jobDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currentCurrencySymbolProvider);
    final job = jobDetails.job;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Job #${job.id.toString().padLeft(6, '0')}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(DateFormat('MMM d, yyyy').format(job.completionDate ?? job.creationDate), style: textTheme.titleSmall),
          ],
        ),
        subtitle: Text('Status: ${job.status} | Total: ${NumberFormat.currency(symbol: '$currencySymbol ').format(job.totalAmount)}'),
        children: [
          _buildItemsList('Services', jobDetails.serviceItems, textTheme),
          _buildItemsList('Parts', jobDetails.inventoryItems, textTheme),
          _buildItemsList('Others', jobDetails.otherItems, textTheme),
        ],
      ),
    );
  }

  Widget _buildItemsList(String title, List<RepairJobItem> items, TextTheme textTheme) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          ...items.map((item) => ListTile(
            dense: true,
            title: Text(item.description),
            trailing: Text('Qty: ${item.quantity}'),
          )),
        ],
      ),
    );
  }
}

