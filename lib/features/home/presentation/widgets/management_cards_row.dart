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
            title: 'Customers',
            icon: Icons.people_alt_outlined,
            iconColor: Colors.teal.shade600,
            onTap: () => context.go('/customers'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Vehicles',
            icon: Icons.directions_car_outlined,
            iconColor: Colors.indigo.shade600,
            onTap: () => context.go('/vehicle_models'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Inventory',
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.brown.shade600,
            onTap: () => context.go('/inventory'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Repair Services',
            icon: Icons.build_circle_outlined,
            iconColor: Colors.pink.shade600,
            onTap: () => context.go('/services'),
          ),
        ),
        // --- FIX: Added new card for Reminder Intervals ---
        const SizedBox(width: 20),
        Expanded(
          child: _ManagementCard(
            title: 'Reminder Intervals',
            icon: Icons.alarm_on_outlined,
            iconColor: Colors.orange.shade700,
            onTap: () => context.push('/reminders/intervals'),
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

