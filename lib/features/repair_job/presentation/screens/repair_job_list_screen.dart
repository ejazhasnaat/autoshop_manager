// lib/features/repair_job/presentation/screens/repair_job_list_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// --- ADDED: Provider to hold the search query for repair jobs ---
final repairJobSearchQueryProvider = StateProvider<String>((ref) => '');

// --- ADDED: Provider to filter the active jobs based on the search query ---
final filteredActiveRepairJobsProvider =
    Provider<AsyncValue<List<RepairJobWithCustomer>>>((ref) {
  final activeJobsAsync = ref.watch(activeRepairJobsProvider);
  final searchTerm = ref.watch(repairJobSearchQueryProvider).toLowerCase();

  return activeJobsAsync.whenData((jobs) {
    if (searchTerm.isEmpty) {
      return jobs;
    }
    return jobs.where((jobWithCustomer) {
      final job = jobWithCustomer.repairJob;
      final customer = jobWithCustomer.customer;
      final vehicle = jobWithCustomer.vehicle;

      // --- FIX: Added null-aware checks (?.) and null-coalescing (?? false) to prevent crash on null vehicle make/model ---
      return customer.name.toLowerCase().contains(searchTerm) ||
          (vehicle.make?.toLowerCase().contains(searchTerm) ?? false) ||
          (vehicle.model?.toLowerCase().contains(searchTerm) ?? false) ||
          vehicle.registrationNumber.toLowerCase().contains(searchTerm) ||
          job.status.toLowerCase().contains(searchTerm) ||
          job.id.toString().contains(searchTerm);
    }).toList();
  });
});

class RepairJobListScreen extends ConsumerWidget {
  const RepairJobListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- UPDATED: Watch the new filtered provider ---
    final filteredJobsAsync = ref.watch(filteredActiveRepairJobsProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Active Repair Jobs'),
      // --- UPDATED: Main body is now a Column to accommodate the search bar ---
      body: Column(
        children: [
          // --- ADDED: Search bar and Add button section, styled like the customer screen ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => ref
                        .read(repairJobSearchQueryProvider.notifier)
                        .state = value,
                    decoration: InputDecoration(
                      hintText: 'Search by Customer, Vehicle, Status, or Job #',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Repair Job'),
                  onPressed: () => context.go('/repairs/add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- UPDATED: The list is now wrapped in an Expanded widget ---
          Expanded(
            child: filteredJobsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active repair jobs.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final jobWithCustomer = jobs[index];
                    return _RepairJobCard(jobWithCustomer: jobWithCustomer);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('An error occurred: $error'),
              ),
            ),
          ),
        ],
      ),
      // --- REMOVED: FloatingActionButton is replaced by the new ElevatedButton ---
    );
  }
}

class _RepairJobCard extends ConsumerWidget {
  final RepairJobWithCustomer jobWithCustomer;

  const _RepairJobCard({required this.jobWithCustomer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(userPreferencesStreamProvider);
    final currencySymbol = preferencesAsync.value?.defaultCurrency ?? 'PKR';

    final job = jobWithCustomer.repairJob;
    final customer = jobWithCustomer.customer;
    final vehicle = jobWithCustomer.vehicle;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/repairs/edit/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${vehicle.make} ${vehicle.model} (${vehicle.registrationNumber})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(job.status),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle:
                        TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // --- UPDATED: Added Job # next to the customer name ---
              Text(
                'Customer: ${customer.name} | Job #${job.id.toString().padLeft(6, '0')}',
                style: const TextStyle(fontSize: 15),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${NumberFormat.currency(symbol: '$currencySymbol ').format(job.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // --- FIX: Updated the date format string to remove the comma ---
                  Text(
                    'Created: ${DateFormat('EEEE MMM d, yyyy : hh:mm a').format(job.creationDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

