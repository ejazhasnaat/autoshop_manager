// lib/features/home/presentation/screens/home_screen.dart
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/features/home/presentation/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final upcomingServicesAsync = ref.watch(upcomingServicesProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Dashboard'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                // --- UPDATED: Welcome message uses full name ---
                'Welcome, ${authState.user?.fullName ?? authState.user?.username ?? 'Guest'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              if (authState.isAdmin)
                Text(
                  '(Admin User)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              upcomingServicesAsync.when(
                data: (vehicles) => vehicles.isEmpty
                    ? const SizedBox.shrink()
                    : _buildUpcomingServicesCard(context, vehicles),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20.0,
                runSpacing: 20.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureButton(
                    context,
                    label: 'Customers',
                    icon: Icons.people_outline,
                    onPressed: () => context.go('/customers'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Inventory',
                    icon: Icons.inventory_2_outlined,
                    onPressed: () => context.go('/inventory'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Orders',
                    icon: Icons.receipt_long_outlined,
                    onPressed: () => context.go('/orders'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Reminders',
                    icon: Icons.notifications_active_outlined,
                    onPressed: () => context.go('/reminders'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Repair Services',
                    icon: Icons.design_services_outlined,
                    onPressed: () => context.go('/services'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Vehicle Models',
                    icon: Icons.directions_car_outlined,
                    onPressed: () => context.go('/vehicle_models'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Reports',
                    icon: Icons.bar_chart_outlined,
                    onPressed: () => context.go('/reports'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingServicesCard(
    BuildContext context,
    List<Vehicle> vehicles,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Services',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ListView.separated(
              itemCount: vehicles.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _UpcomingServiceTile(vehicle: vehicle);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      height: 120,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingServiceTile extends ConsumerWidget {
  final Vehicle vehicle;
  const _UpcomingServiceTile({required this.vehicle});

  void _sendManualReminder(BuildContext context, Customer customer) async {
    final reminderType = vehicle.nextReminderType ?? 'service';
    final message = Uri.encodeComponent(
      'Hi ${customer.name}, this is a friendly reminder that your ${vehicle.make ?? ''} ${vehicle.model ?? ''} (Reg: ${vehicle.registrationNumber}) is due for a $reminderType soon. Please contact us to schedule an appointment. Thank you!',
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
    final customerAsync = ref.watch(customerByIdProvider(vehicle.customerId));

    return ListTile(
      title: Text(
        '${vehicle.make ?? ''} ${vehicle.model ?? ''} - ${vehicle.registrationNumber}',
      ),
      subtitle: Text(
        '${vehicle.nextReminderType ?? 'Service'} due on ${DateFormat.yMMMd().format(vehicle.nextReminderDate!)}',
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
      trailing: customerAsync.when(
        data: (customer) => customer == null
            ? const Icon(Icons.error_outline, color: Colors.red)
            : IconButton(
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Send Reminder SMS',
                onPressed: () =>
                    _sendManualReminder(context, customer.customer),
              ),
        loading: () => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, st) => const Icon(Icons.error, color: Colors.red),
      ),
      onTap: () => context.go('/vehicles/${vehicle.id!}'),
    );
  }
}
