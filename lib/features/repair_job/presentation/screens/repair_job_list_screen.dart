// lib/features/repair_job/presentation/screens/repair_job_list_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
// --- FIX: Replaced 'package.flutter' with the correct material library import ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RepairJobListScreen extends ConsumerWidget {
  const RepairJobListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeJobsAsync = ref.watch(activeRepairJobsProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Active Repair Jobs'),
      body: activeJobsAsync.when(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/repairs/add'),
        tooltip: 'New Repair Job',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RepairJobCard extends StatelessWidget {
  final RepairJobWithCustomer jobWithCustomer;

  const _RepairJobCard({required this.jobWithCustomer});

  @override
  Widget build(BuildContext context) {
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
                    labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${customer.name}',
                style: const TextStyle(fontSize: 15),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Total: ${NumberFormat.currency(symbol: 'PKR ').format(job.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Created: ${DateFormat.yMMMd().format(job.creationDate)}',
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
