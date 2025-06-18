// lib/features/customer/presentation/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsyncValue = ref.watch(customerListProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Customers'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/customers/add'),
        child: const Icon(Icons.add),
      ),
      body: customersAsyncValue.when(
        data: (customersWithVehicles) { // Renamed parameter for clarity
          if (customersWithVehicles.isEmpty) {
            return const Center(
              child: Text('No customers found. Add a new customer to get started!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: customersWithVehicles.length,
            itemBuilder: (context, index) {
              final customerWithVehicles = customersWithVehicles[index];
              final customer = customerWithVehicles.customer; // Get the actual Customer object
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    customer.name, // Access customer.name
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Phone: ${customer.phoneNumber}'), // Access customer.phoneNumber
                      if (customer.whatsappNumber != null && customer.whatsappNumber!.isNotEmpty)
                        Text('WhatsApp: ${customer.whatsappNumber!}'),
                      if (customer.email != null && customer.email!.isNotEmpty)
                        Text('Email: ${customer.email}'), // Access customer.email
                      if (customer.address != null && customer.address!.isNotEmpty)
                        Text('Address: ${customer.address}'), // Access customer.address
                      if (customerWithVehicles.vehicles.isNotEmpty) // Display first vehicle's registration
                        Text('Vehicle: ${customerWithVehicles.vehicles.first.registrationNumber} ${customerWithVehicles.vehicles.length > 1 ? '(+${customerWithVehicles.vehicles.length - 1} more)' : ''}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          context.go('/customers/edit/${customer.id}'); // Access customer.id
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Show a confirmation dialog
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete customer "${customer.name}"?'), // Access customer.name
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.id!); // Access customer.id
                                    Navigator.of(ctx).pop(); // Dismiss dialog
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // <--- NEW: Navigate to CustomerDetailScreen on tap --->
                    context.go('/customers/${customer.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

