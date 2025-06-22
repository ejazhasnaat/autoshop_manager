// lib/features/vehicle/presentation/screens/vehicle_detail_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final int vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  void _sendManualReminder(BuildContext context, Vehicle vehicle, Customer customer) async {
    final reminderType = vehicle.nextReminderType ?? 'service';
    final message = Uri.encodeComponent(
      'Hi ${customer.name}, this is a friendly reminder that your ${vehicle.make ?? ''} ${vehicle.model ?? ''} (Reg: ${vehicle.registrationNumber}) is due for a $reminderType soon. Please contact us to schedule an appointment. Thank you!'
    );
    final phoneNumber = customer.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('sms:$phoneNumber&body=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch SMS app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicleId));

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Vehicle Details',
        showBackButton: true,
        customActions: [
          vehicleAsync.whenData((vehicle) => IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/vehicles/edit/${vehicle?.id}?customerId=${vehicle?.customerId}'),
          )).value ?? const SizedBox(),
        ],
      ),
      body: vehicleAsync.when(
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(child: Text('Vehicle not found'));
          }
          final customerAsync = ref.watch(customerByIdProvider(vehicle.customerId));
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDetailCard(
                'Vehicle Info',
                {
                  'Registration': vehicle.registrationNumber,
                  'Make': vehicle.make,
                  'Model': vehicle.model,
                  'Year': vehicle.year?.toString(),
                  'Current Mileage': vehicle.currentMileage?.toString(),
                },
                // --- FIXED: Removed the unnecessary list brackets [] ---
                actions: customerAsync.when(
                  data: (customerData) => TextButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Reminder'),
                    onPressed: () {
                      if (customerData != null) {
                        _sendManualReminder(context, vehicle, customerData.customer);
                      }
                    },
                  ),
                  loading: () => const SizedBox(),
                  error: (e, st) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailCard('Service History', {
                'Next Reminder For': vehicle.nextReminderType,
                'Next Reminder Date': _formatDate(vehicle.nextReminderDate),
                'Last General Service': _formatDate(vehicle.lastGeneralServiceDate),
                'at Mileage': vehicle.lastGeneralServiceMileage?.toString(),
                'Last Engine Oil Change': _formatDate(vehicle.lastEngineOilChangeDate),
                'at Mileage ': vehicle.lastEngineOilChangeMileage?.toString(),
                'Last Gear Oil Change': _formatDate(vehicle.lastGearOilChangeDate),
                'at Mileage  ': vehicle.lastGearOilChangeMileage?.toString(),
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat.yMMMd().format(date);
  }

  Widget _buildDetailCard(String title, Map<String, String?> details, {Widget? actions}) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: details.entries
                .where((entry) => entry.value != null && entry.value!.isNotEmpty)
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(entry.value!),
                        ],
                      ),
                    ))
                .toList(),
            ),
          ),
          if (actions != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: actions,
            ),
          ]
        ],
      ),
    );
  }
}
