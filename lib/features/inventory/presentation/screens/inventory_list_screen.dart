// lib/features/inventory/presentation/screens/inventory_list_screen.dart
import 'package:autoshop_manager/core/extensions/iterable_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/inventory/presentation/inventory_providers.dart';
import 'package:autoshop_manager/widgets/common_app_bar.dart';
import 'package:autoshop_manager/features/vehicle/presentation/vehicle_model_providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/core/constants/app_constants.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilterOptions = false;

  String? _filterMake;
  String? _filterModel;
  int? _filterYear;

  Set<String> _visibleColumns = {
    'name',
    'quantity',
    'salePrice',
    'partNumber',
    'supplier',
    'stockLocation',
    'vehicleCompatibility',
  };

  final Map<String, ({String label, int flex})> _allColumnProperties = {
    'name': (label: 'Item Name', flex: 4),
    'partNumber': (label: 'Part No.', flex: 3),
    'quantity': (label: 'Qty', flex: 1),
    'salePrice': (label: 'Sale Price', flex: 2),
    'supplier': (label: 'Supplier', flex: 3),
    'stockLocation': (label: 'Location', flex: 2),
    'vehicleCompatibility': (label: 'Vehicle Comp.', flex: 4),
  };

  @override
  void initState() {
    super.initState();
    final currentFilterState = ref.read(inventoryListFilterStateProvider);
    _searchController.text = currentFilterState.searchTerm ?? '';
    _filterMake = currentFilterState.make;
    _filterModel = currentFilterState.model;
    _filterYear = currentFilterState.year;

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    final currentSortState = ref.read(inventoryListFilterStateProvider);
    ref
        .read(inventoryNotifierProvider.notifier)
        .applyFiltersAndSort(
          searchTerm: _searchController.text.isEmpty
              ? null
              : _searchController.text,
          make: _filterMake,
          model: _filterModel,
          year: _filterYear,
          sortBy: currentSortState.sortBy,
          sortAscending: currentSortState.sortAscending,
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _filterMake = null;
      _filterModel = null;
      _filterYear = null;
      _showFilterOptions = false;
    });
    ref.read(inventoryListFilterStateProvider.notifier).state =
        InventoryListFilterState();
    _applyFiltersAndSort();
  }

  void _toggleSort(String column) {
    final currentSortState = ref.read(inventoryListFilterStateProvider);
    bool newSortAscending = true;
    if (currentSortState.sortBy == column) {
      newSortAscending = !currentSortState.sortAscending;
    }
    
    ref.read(inventoryListFilterStateProvider.notifier).update(
          (state) => state.copyWith(sortBy: column, sortAscending: newSortAscending),
    );
    _applyFiltersAndSort();
  }

  List<MapEntry<String, ({String label, int flex})>>
  _getVisibleColumnProperties() {
    return _allColumnProperties.entries
        .where((entry) => _visibleColumns.contains(entry.key))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleModelsAsync = ref.watch(vehicleModelListProvider);
    final inventoryItemsAsync = ref.watch(inventoryNotifierProvider);
    final currentSortState = ref.watch(inventoryListFilterStateProvider);
    final currentCurrencySymbol = ref.watch(currentCurrencySymbolProvider);

    final List<MapEntry<String, ({String label, int flex})>>
    visibleColumnProperties = _getVisibleColumnProperties();

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Inventory',
      ),
      // --- REMOVED: Old FloatingActionButton ---
      body: Column(
        children: [
          // --- ADDED: New unified control bar for search, add, and filter actions ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Part No, Supplier...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                       suffixIcon: _searchController.text.isNotEmpty 
                       ? IconButton(
                           icon: const Icon(Icons.clear),
                           onPressed: _clearFilters,
                         )
                       : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  onPressed: () => context.go('/inventory/add'),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showFilterOptions ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilterOptions = !_showFilterOptions;
                    });
                  },
                  tooltip: 'Toggle Filters',
                ),
                 PopupMenuButton<String>(
                  icon: const Icon(Icons.view_column),
                  onSelected: (String columnKey) {
                    setState(() {
                      if (columnKey == 'name' ||
                          columnKey == 'quantity' ||
                          columnKey == 'salePrice') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot hide essential columns (Name, Quantity, Sale Price).',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_visibleColumns.contains(columnKey)) {
                        _visibleColumns.remove(columnKey);
                      } else {
                        _visibleColumns.add(columnKey);
                      }
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _allColumnProperties.entries.map((entry) {
                      final columnKey = entry.key;
                      final columnLabel = entry.value.label;
                      final isCoreColumn =
                          columnKey == 'name' ||
                          columnKey == 'quantity' ||
                          columnKey == 'salePrice';
                      return CheckedPopupMenuItem<String>(
                        value: columnKey,
                        checked: _visibleColumns.contains(columnKey),
                        enabled: !isCoreColumn,
                        child: Text(columnLabel),
                      );
                    }).toList();
                  },
                  tooltip: 'Manage Columns',
                ),
              ],
            ),
          ),
          // --- REMOVED: Old search bar widget ---
          if (_showFilterOptions)
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: vehicleModelsAsync.when(
                  data: (vehicleModels) {
                    final uniqueMakes =
                        vehicleModels.map((vm) => vm.make).toSet().toList()
                          ..sort();

                    final filteredModels =
                        vehicleModels
                            .where((vm) => vm.make == _filterMake)
                            .map((vm) => vm.model)
                            .toSet()
                            .toList()
                          ..sort();

                    final selectedVehicleModel = vehicleModels.firstWhereOrNull(
                      (vm) =>
                          vm.make == _filterMake && vm.model == _filterModel,
                    );

                    final List<int> years = [];
                    if (selectedVehicleModel != null) {
                      final yearFrom = selectedVehicleModel.yearFrom ?? 1900;
                      final yearTo =
                          selectedVehicleModel.yearTo ?? DateTime.now().year;
                      for (int i = yearTo; i >= yearFrom; i--) {
                        years.add(i);
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by Vehicle Compatibility',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        DropdownButtonFormField<String>(
                          value: _filterMake,
                          decoration: const InputDecoration(labelText: 'Make'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Makes'),
                            ),
                            ...uniqueMakes.map((make) {
                              return DropdownMenuItem(
                                value: make,
                                child: Text(make),
                              );
                            }).toList(),
                          ],
                          onChanged: (newValue) {
                            setState(() {
                              _filterMake = newValue;
                              _filterModel = null;
                              _filterYear = null;
                            });
                            _applyFiltersAndSort();
                          },
                          hint: const Text('Select Make'),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _filterModel,
                          decoration: const InputDecoration(labelText: 'Model'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Models'),
                            ),
                            ...(_filterMake == null
                                ? []
                                : filteredModels.map((model) {
                                    return DropdownMenuItem(
                                      value: model,
                                      child: Text(model),
                                    );
                                  }).toList()),
                          ],
                          onChanged: _filterMake == null
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _filterModel = newValue;
                                    _filterYear = null;
                                  });
                                  _applyFiltersAndSort();
                                },
                          hint: const Text('Select Model'),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _filterYear,
                          decoration: const InputDecoration(labelText: 'Year'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Years'),
                            ),
                            ...(_filterModel == null
                                ? []
                                : years.map((year) {
                                    return DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    );
                                  }).toList()),
                          ],
                          onChanged: _filterModel == null
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _filterYear = newValue;
                                  });
                                  _applyFiltersAndSort();
                                },
                          hint: const Text('Select Year'),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading vehicle models: $err')),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                ...visibleColumnProperties.map((entry) {
                  final columnKey = entry.key;
                  final columnLabel = entry.value.label;
                  final columnFlex = entry.value.flex;
                  return _buildSortableHeader(
                    columnKey,
                    columnLabel,
                    columnFlex,
                    currentSortState,
                  );
                }).toList(),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Expanded(
            child: inventoryItemsAsync.when(
              data: (inventoryItems) {
                if (inventoryItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No inventory items found. Add some or adjust filters!',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0),
                  itemCount: inventoryItems.length,
                  itemBuilder: (context, index) {
                    final item = inventoryItems[index];
                    final isLowStock =
                        item.quantity < AppConstants.lowStockThreshold;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 4.0,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            ...visibleColumnProperties.map((entry) {
                              final columnKey = entry.key;
                              final columnFlex = entry.value.flex;
                              return Expanded(
                                flex: columnFlex,
                                child: _buildItemCell(
                                  item,
                                  columnKey,
                                  isLowStock,
                                  currentCurrencySymbol,
                                ),
                              );
                            }).toList(),
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.all(4.0),
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      context.go('/inventory/edit/${item.id}');
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: const EdgeInsets.all(4.0),
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: Text(
                                            'Are you sure you want to delete "${item.name}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      inventoryNotifierProvider
                                                          .notifier,
                                                    )
                                                    .deleteInventoryItem(
                                                      item.id!,
                                                    );
                                                Navigator.of(ctx).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(
    String columnKey,
    String label,
    int flex,
    InventoryListFilterState currentSortState,
  ) {
    final isCurrentSortColumn = currentSortState.sortBy == columnKey;
    final sortIcon = isCurrentSortColumn
        ? (currentSortState.sortAscending
              ? Icons.arrow_upward
              : Icons.arrow_downward)
        : null;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(columnKey),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sortIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  sortIcon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCell(
    InventoryItem item,
    String columnKey,
    bool isLowStock,
    String currencySymbol,
  ) {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodyMedium;
    final TextStyle? lowStockTextStyle = textStyle?.copyWith(
      color: Colors.orange.shade700,
      fontWeight: FontWeight.bold,
    );

    Widget content;
    switch (columnKey) {
      case 'name':
        content = Text(
          item.name,
          style: isLowStock ? lowStockTextStyle : textStyle,
          overflow: TextOverflow.ellipsis,
        );
        break;
      case 'partNumber':
        content = Text(
          item.partNumber ?? 'N/A',
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        );
        break;
      case 'quantity':
        content = Text(
          '${item.quantity}',
          style: isLowStock ? lowStockTextStyle : textStyle,
        );
        break;
      case 'salePrice':
        content = Text(
          '$currencySymbol ${item.salePrice.toStringAsFixed(2)}',
          style: textStyle,
        );
        break;
      case 'supplier':
        content = Text(
          item.supplier ?? 'N/A',
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        );
        break;
      case 'stockLocation':
        content = Text(
          item.stockLocation ?? 'N/A',
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        );
        break;
      case 'vehicleCompatibility':
        final String compatibilityText =
            item.vehicleMake != null && item.vehicleMake!.isNotEmpty
            ? '${item.vehicleMake!} ${item.vehicleModel ?? ''} (${item.vehicleYearFrom ?? ''}-${item.vehicleYearTo ?? ''})'
                  .trim()
            : 'N/A';
        content = Text(
          compatibilityText,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        );
        break;
      default:
        content = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Align(
        alignment: _getColumnAlignment(columnKey),
        child: content,
      ),
    );
  }

  Alignment _getColumnAlignment(String columnKey) {
    return Alignment.centerLeft;
  }
}

