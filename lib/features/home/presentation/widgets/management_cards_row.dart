// lib/features/home/presentation/widgets/management_cards_row.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagementCardsRow extends StatelessWidget {
  const ManagementCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ManagementCard(
            title: 'Manage Customers',
            icon: Icons.people_alt_outlined,
            iconColor: Colors.teal.shade600,
            onTap: () => context.go('/customers'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Manage Vehicles',
            icon: Icons.directions_car_outlined,
            iconColor: Colors.indigo.shade600,
            // UPDATED: This card now navigates directly to the add vehicle screen.
            onTap: () => context.go('/vehicle_models'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Manage Inventory',
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.brown.shade600,
            onTap: () => context.go('/inventory'),
          ),
        ),
      ],
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Use a Flexible widget to allow the title to wrap if necessary.
                  Flexible(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              // You can add a subtitle or description here if needed in the future.
              Text(
                'Click to view and manage',
                style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

