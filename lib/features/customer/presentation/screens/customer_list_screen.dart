// lib/features/customer/presentation/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/customer/presentation/customer_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart'; // For Customer type
import 'package:url_launcher/url_launcher.dart'; // For messaging

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // --- ADDED: A list of colors for the vehicle icons ---
  final List<Color> _vehicleIconColors = const [
    Colors.blue,
    Colors.teal,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage(
    BuildContext context,
    Customer customer,
    String type,
  ) async {
    final String phoneNumber =
        (type == 'whatsapp' &&
            customer.whatsappNumber != null &&
            customer.whatsappNumber!.isNotEmpty)
        ? customer.whatsappNumber!
        : customer.phoneNumber;

    final String sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri url;

    if (type == 'sms') {
      url = Uri.parse('sms:$sanitizedPhone');
    } else {
      url = Uri.parse('https://wa.me/$sanitizedPhone');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $type.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsyncValue = ref.watch(customerListProvider);
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
                    controller: _searchController,
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
            child: customersAsyncValue.when(
              data: (customersWithVehicles) {
                final filteredList = customersWithVehicles.where((c) {
                  final searchTerm = _searchController.text.toLowerCase();
                  if (searchTerm.isEmpty) return true;
                  final customer = c.customer;
                  final vehicleMatch = c.vehicles.any(
                    (v) =>
                        v.registrationNumber.toLowerCase().contains(searchTerm),
                  );

                  return customer.name.toLowerCase().contains(searchTerm) ||
                      customer.phoneNumber.toLowerCase().contains(searchTerm) ||
                      vehicleMatch;
                }).toList();

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
                    final customer = customerWithVehicles.customer;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 4.0,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              flex: 8,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  Icon(
                                    Icons.phone_android,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    customer.whatsappNumber ?? 'N/A',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  // --- UPDATED: Vehicle list now includes colored icons ---
                                  if (customerWithVehicles
                                      .vehicles
                                      .isNotEmpty) ...[
                                    Text(
                                      '|',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    // Use asMap().entries to get index for color selection
                                    ...customerWithVehicles.vehicles
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          int idx = entry.key;
                                          var vehicle = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6.0,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.directions_car,
                                                  // Cycle through the colors list
                                                  color:
                                                      _vehicleIconColors[idx %
                                                          _vehicleIconColors
                                                              .length],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  vehicle.registrationNumber,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sms_rounded),
                                    color: Colors.orangeAccent,
                                    tooltip: 'Send SMS',
                                    onPressed: () =>
                                        _sendMessage(context, customer, 'sms'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat_rounded),
                                    color: Colors.green,
                                    tooltip: 'Send WhatsApp',
                                    onPressed: () => _sendMessage(
                                      context,
                                      customer,
                                      'whatsapp',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  Icons.phone,
                                  'Phone',
                                  customer.phoneNumber,
                                ),
                                if (customer.email != null &&
                                    customer.email!.isNotEmpty)
                                  _buildDetailRow(
                                    Icons.email,
                                    'Email',
                                    customer.email!,
                                  ),
                                if (customer.address != null &&
                                    customer.address!.isNotEmpty)
                                  _buildDetailRow(
                                    Icons.location_on,
                                    'Address',
                                    customer.address!,
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      onPressed: () => context.go(
                                        '/customers/edit/${customer.id}',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (authState.isAdmin)
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () => _showDeleteDialog(
                                          context,
                                          ref,
                                          customer,
                                        ),
                                      ),
                                    const Spacer(),
                                    ElevatedButton(
                                      child: const Text('View Details'),
                                      onPressed: () => context.go(
                                        '/customers/${customer.id}',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic customer,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete customer "${customer.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(customerNotifierProvider.notifier)
                  .deleteCustomer(customer.id!);
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
