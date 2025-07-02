// lib/features/home/presentation/widgets/quick_actions_panel.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _QuickActionButton(
              icon: Icons.add,
              color: Colors.green,
              title: 'New Repair Job',
              subtitle: 'Create a new repair job',
              onTap: () => context.go('/repairs/add'),
            ),
            _QuickActionButton(
              icon: Icons.person_add_alt_1_outlined,
              color: Colors.blue,
              title: 'Add Customer',
              subtitle: 'Register new customer',
              onTap: () => context.go('/customers/add?from=/home'),
            ),
            _QuickActionButton(
              icon: Icons.calendar_today_outlined,
              color: Colors.deepPurple,
              title: 'Schedule',
              subtitle: 'View appointments',
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.notifications_active_outlined,
              color: Colors.orange,
              title: 'Service Reminders',
              subtitle: 'Manage customer reminders',
              onTap: () => context.go('/reminders'),
            ),
            _QuickActionButton(
              icon: Icons.inventory_2_outlined,
              color: Colors.teal,
              title: 'Inventory',
              subtitle: 'Manage parts & supplies',
              onTap: () => context.go('/inventory'),
            ),
            _QuickActionButton(
              icon: Icons.bar_chart_outlined,
              color: Colors.pink,
              title: 'Reports',
              subtitle: 'Generate reports',
              onTap: () => context.go('/reports'),
            ),
            _QuickActionButton(
              icon: Icons.settings_outlined,
              color: Colors.grey.shade600,
              title: 'Settings',
              subtitle: 'System configuration',
              onTap: () => context.go('/settings'),
            ),
            const Divider(height: 32),
            Text(
              'Emergency Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/repairs/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Emergency Repair'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/repairs/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Priority Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Each action is now a Card for a distinct, bordered look ---
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 16.0,
        ),
      ),
    );
  }
}
