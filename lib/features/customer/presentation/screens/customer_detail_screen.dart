// lib/features/customer/presentation/screens/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  void _sendMessage(BuildContext context, String phoneNumber, String type, WidgetRef ref) async {
    final String sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri url;

    if (type == 'sms') {
      url = Uri.parse('sms:$sanitizedPhone');
    } else {
      final customer = ref.read(customerByIdProvider(customerId)).value?.customer;
      final whatsappNumber = customer?.whatsappNumber ?? sanitizedPhone;
      url = Uri.parse('https://wa.me/$whatsappNumber');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $type. Is the app installed?')),
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerWithVehiclesAsync = ref.watch(customerByIdProvider(customerId));

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customer Details',
        showBackButton: true,
        customActions: [
          customerWithVehiclesAsync.when(
            data: (customerWithVehicles) {
              if (customerWithVehicles != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.go('/customers/edit/${customerWithVehicles.customer.id}');
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: customerWithVehiclesAsync.when(
        data: (customerWithVehicles) {
          if (customerWithVehicles == null) {
            return const Center(child: Text('Customer not found.'));
          }

          final customer = customerWithVehicles.customer;
          final vehicles = customerWithVehicles.vehicles;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Name:', customer.name),
                        _buildPhoneRow(context, 'Phone Number:', customer.phoneNumber, ref),
                        if (customer.whatsappNumber != null && customer.whatsappNumber!.isNotEmpty)
                          _buildDetailRow(context, 'WhatsApp Number:', customer.whatsappNumber!),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          _buildDetailRow(context, 'Email:', customer.email!),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          _buildDetailRow(context, 'Address:', customer.address!),
                      ],
                    ),
                  ),
                ),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Associated Vehicles',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              tooltip: 'Add New Vehicle',
                              onPressed: () {
                                context.push('/vehicles/add/$customerId');
                              },
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        if (vehicles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No vehicles associated with this customer.'),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    context.push('/vehicles/${vehicle.id}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Registration: ${vehicle.registrationNumber}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        if (vehicle.make != null && vehicle.make!.isNotEmpty)
                                          Text('Make: ${vehicle.make!}'),
                                        if (vehicle.model != null && vehicle.model!.isNotEmpty)
                                          Text('Model: ${vehicle.model!}'),
                                        if (vehicle.year != null)
                                          Text('Year: ${vehicle.year!}'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, String label, String value, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sms_rounded, color: Colors.orangeAccent),
            onPressed: () => _sendMessage(context, value, 'sms', ref),
            tooltip: 'Send SMS',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.chat_rounded, color: Colors.green),
            onPressed: () => _sendMessage(context, value, 'whatsapp', ref),
            tooltip: 'Send WhatsApp',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
