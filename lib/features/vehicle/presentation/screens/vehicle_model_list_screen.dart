// lib/features/vehicle/presentation/screens/vehicle_model_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_model_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';

class VehicleModelListScreen extends ConsumerStatefulWidget {
  const VehicleModelListScreen({super.key});

  @override
  ConsumerState<VehicleModelListScreen> createState() => _VehicleModelListScreenState();
}

class _VehicleModelListScreenState extends ConsumerState<VehicleModelListScreen> {
  final TextEditingController _searchController = TextEditingController();
  // --- UPDATE 3: State variable to track which 'Make' is currently expanded ---
  String? _expandedMake;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<VehicleModel>> _groupAndFilterModels(
      List<VehicleModel> models, String searchTerm) {
    final grouped = <String, List<VehicleModel>>{};
    
    for (final model in models) {
      (grouped[model.make] ??= []).add(model);
    }

    if (searchTerm.isEmpty) {
      return grouped;
    }

    final filtered = <String, List<VehicleModel>>{};
    final lowerCaseSearchTerm = searchTerm.toLowerCase();

    grouped.forEach((make, modelList) {
      if (make.toLowerCase().contains(lowerCaseSearchTerm)) {
        filtered[make] = modelList;
      } else {
        final matchingModels = modelList.where((model) {
          return model.model.toLowerCase().contains(lowerCaseSearchTerm);
        }).toList();

        if (matchingModels.isNotEmpty) {
          filtered[make] = matchingModels;
        }
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleModelsAsync = ref.watch(vehicleModelListProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Vehicles'),
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
                      labelText: 'Search by Make or Model',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // --- UPDATE 2: Changed IconButton to a styled ElevatedButton ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                  onPressed: () => context.go('/vehicle_models/add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: vehicleModelsAsync.when(
              data: (vehicleModels) {
                final groupedData = _groupAndFilterModels(vehicleModels, _searchController.text);
                final makes = groupedData.keys.toList()..sort();

                if (makes.isEmpty) {
                  return const Center(
                    child: Text('No vehicle models found. Add a new model or adjust search!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  itemCount: makes.length,
                  itemBuilder: (context, index) {
                    final make = makes[index];
                    final models = groupedData[make]!;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        title: Text(make, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('${models.length} model(s)'),
                        // --- UPDATE 4: Highlight row when expanded ---
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        children: models.map((model) => _buildModelTile(context, ref, model)).toList(),
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

  Widget _buildModelTile(BuildContext context, WidgetRef ref, VehicleModel model) {
    final authState = ref.watch(authNotifierProvider);

    return ListTile(
      title: Text(model.model),
      subtitle: (model.yearFrom != null || model.yearTo != null)
          ? Text('Years: ${model.yearFrom ?? '?'} - ${model.yearTo ?? 'Present'}')
          : null,
      trailing: SizedBox(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Edit Model',
              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                context.go('/vehicle_models/edit?make=${Uri.encodeComponent(model.make)}&model=${Uri.encodeComponent(model.model)}');
              },
            ),
            if (authState.isAdmin)
              IconButton(
                tooltip: 'Delete Model',
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
                            Navigator.of(ctx).pop();
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
  }
}
