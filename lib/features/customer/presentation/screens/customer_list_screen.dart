// lib/features/customer/presentation/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
// This import makes the CustomerWithVehicles type available
import 'package:autoshop_manager/data/repositories/customer_repository.dart';

// OPTIMIZATION: Provider for the search query.
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// OPTIMIZATION: Memoized provider for the filtered list.
final filteredCustomerListProvider = Provider<AsyncValue<List<CustomerWithVehicles>>>((ref) {
  final customersAsyncValue = ref.watch(customerListProvider);
  final searchTerm = ref.watch(customerSearchQueryProvider).toLowerCase();

  return customersAsyncValue.whenData((customersWithVehicles) {
    if (searchTerm.isEmpty) {
      return customersWithVehicles;
    }
    return customersWithVehicles.where((c) {
      final customer = c.customer;
      final vehicleMatch = c.vehicles.any(
        (v) => v.registrationNumber.toLowerCase().contains(searchTerm),
      );
      return customer.name.toLowerCase().contains(searchTerm) ||
          customer.phoneNumber.toLowerCase().contains(searchTerm) ||
          vehicleMatch;
    }).toList();
  });
});


class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredCustomersAsyncValue = ref.watch(filteredCustomerListProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Customers'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        ref.read(customerSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Phone or Vehicle No.',
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
                  label: const Text('Add Customer'),
                  onPressed: () => context.go('/customers/add'),
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
          Expanded(
            child: filteredCustomersAsyncValue.when(
              data: (filteredList) {
                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No customers found. Add a new customer to get started!',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final customerWithVehicles = filteredList[index];
                    return CustomerListItem(
                      customerWithVehicles: customerWithVehicles,
                      isAdmin: authState.isAdmin,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerListItem extends ConsumerWidget {
  final CustomerWithVehicles customerWithVehicles;
  final bool isAdmin;
  final List<Color> _vehicleIconColors = const [ Colors.blue, Colors.teal, Colors.purple, Colors.brown, Colors.indigo, ];

  const CustomerListItem({
    super.key,
    required this.customerWithVehicles,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Customer customer = customerWithVehicles.customer;
    final List<Vehicle> vehicles = customerWithVehicles.vehicles;

    final List<Widget> vehicleWidgets = [];
    if (vehicles.isNotEmpty) {
      for (var i = 0; i < vehicles.length; i++) {
        final vehicle = vehicles[i];
        vehicleWidgets.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, color: _vehicleIconColors[i % _vehicleIconColors.length], size: 16),
              const SizedBox(width: 4),
              Text(vehicle.registrationNumber, style: Theme.of(context).textTheme.bodyLarge),
            ],
          )
        );
        if (i < vehicles.length - 1) {
          vehicleWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('/', style: TextStyle(color: Colors.grey.shade600)),
            ),
          );
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4.0,
          runSpacing: 4.0,
          children: [
            Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('|', style: TextStyle(color: Colors.grey.shade400)),
            ),
            const Icon(Icons.phone_android, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(customer.phoneNumber, style: Theme.of(context).textTheme.bodyLarge),
            if (vehicles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('|', style: TextStyle(color: Colors.grey.shade400)),
              ),
              ...vehicleWidgets,
            ],
          ],
        ),
        trailing: TextButton.icon(
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Reminder'),
          onPressed: () {
            context.push('/reminders?customerId=${customer.id}&fromCustomerList=true');
          },
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.chat_bubble_outline, 'WhatsApp', customer.whatsappNumber ?? customer.phoneNumber),
                if (customer.email != null && customer.email!.isNotEmpty)
                  _buildDetailRow(Icons.email_outlined, 'Email', customer.email!),
                if (customer.address != null && customer.address!.isNotEmpty)
                  _buildDetailRow(Icons.location_on_outlined, 'Address', customer.address!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      onPressed: () => context.go('/customers/edit/${customer.id}'),
                    ),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => _showDeleteDialog(context, ref, customer),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      child: const Text('View Details'),
                      onPressed: () => context.go('/customers/${customer.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete customer "${customer.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
