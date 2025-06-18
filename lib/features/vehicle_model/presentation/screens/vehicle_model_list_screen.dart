// lib/features/vehicle_model/presentation/screens/vehicle_model_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/vehicle_model/presentation/vehicle_model_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';

class VehicleModelListScreen extends ConsumerWidget {
  const VehicleModelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleModelsAsync = ref.watch(vehicleModelListProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Vehicle Models'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/vehicle_models/add'), // Navigate to add new vehicle model
        child: const Icon(Icons.add),
      ),
      body: vehicleModelsAsync.when(
        data: (vehicleModels) {
          if (vehicleModels.isEmpty) {
            return const Center(
              child: Text('No vehicle models found. Add a new model to get started!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: vehicleModels.length,
            itemBuilder: (context, index) {
              final model = vehicleModels[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    '${model.make} ${model.model}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (model.yearFrom != null || model.yearTo != null)
                        Text(
                          'Years: ${model.yearFrom ?? ''} - ${model.yearTo ?? 'Present'}'.trim(),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          // Navigate to edit screen for this vehicle model
                          // Passing make and model as path parameters for editing composite key
                          context.go('/vehicle_models/edit/${model.make}/${model.model}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete model "${model.make} ${model.model}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(vehicleModelNotifierProvider.notifier).deleteVehicleModel(model.make, model.model);
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

