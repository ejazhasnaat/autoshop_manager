// lib/features/customer/presentation/screens/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Vehicle type
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // For CommonAppBar

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerWithVehiclesAsync = ref.watch(customerByIdProvider(customerId));

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customer Details',
        showBackButton: true, // Always show back button for detail screen
        customActions: [ // <--- FIX: Changed 'actions' to 'customActions'
          customerWithVehiclesAsync.when(
            data: (customerWithVehicles) {
              if (customerWithVehicles != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to edit screen for this customer
                    context.go('/customers/edit/${customerWithVehicles.customer.id}');
                  },
                );
              }
              return const SizedBox.shrink(); // No edit button if data not loaded
            },
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (err, stack) => const SizedBox.shrink(), // No edit button on error
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
                // Customer Details Section
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
                        _buildDetailRow(context, 'Phone Number:', customer.phoneNumber),
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

                // Vehicles Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Associated Vehicles',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Fixed width for labels
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

