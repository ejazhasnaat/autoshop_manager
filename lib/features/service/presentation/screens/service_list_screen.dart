// lib/features/service/presentation/screens/service_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/service/presentation/service_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart'; // <--- NEW IMPORT


class ServiceListScreen extends ConsumerWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsyncValue = ref.watch(serviceListProvider);
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider); // <--- WATCH CURRENCY

    return Scaffold(
      appBar: const CommonAppBar(title: 'Services'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/services/add'),
        tooltip: 'Add New Service',
        child: const Icon(Icons.add),
      ),
      body: servicesAsyncValue.when(
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Text('No services found. Add a new service to get started!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Price: $currentCurrencySymbol${service.price.toStringAsFixed(2)}'), // <--- USE CURRENCY SYMBOL
                      if (service.description != null && service.description!.isNotEmpty)
                        Text('Description: ${service.description!}'),
                      Text('Status: ${service.isActive ? 'Active' : 'Inactive'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                        onPressed: () {
                          context.go('/services/edit/${service.id}');
                        },
                        tooltip: 'Edit Service',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete service "${service.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(serviceNotifierProvider.notifier).deleteService(service.id!);
                                    Navigator.of(ctx).pop();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete Service',
                      ),
                    ],
                  ),
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

