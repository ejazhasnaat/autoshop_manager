// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart'; // For authNotifierProvider
import 'package:autoshop_manager/widgets/common_app_bar.dart'; // For CommonAppBar

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Home'), // Using CommonAppBar
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome, ${authState.user?.username ?? 'Guest'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              if (authState.isAdmin)
                Text(
                  '(Admin User)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20.0, // horizontal space between items
                runSpacing: 20.0, // vertical space between lines
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureButton(
                    context,
                    label: 'Customers',
                    icon: Icons.people,
                    onPressed: () => context.go('/customers'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Inventory',
                    icon: Icons.inventory,
                    onPressed: () => context.go('/inventory'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Orders',
                    icon: Icons.receipt_long,
                    onPressed: () => context.go('/orders'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Services',
                    icon: Icons.design_services,
                    onPressed: () => context.go('/services'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Vehicle Models', // <--- NEW: Vehicle Models Button
                    icon: Icons.directions_car,
                    onPressed: () => context.go('/vehicle_models'),
                  ),
                  _buildFeatureButton(
                    context,
                    label: 'Reports',
                    icon: Icons.bar_chart,
                    onPressed: () => context.go('/reports'),
                  ),
                  if (authState.isAdmin)
                    _buildFeatureButton(
                      context,
                      label: 'Manage Users',
                      icon: Icons.manage_accounts,
                      onPressed: () => context.go('/signup'), // Assuming signup screen is for user management
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 150, // Fixed width for buttons
      height: 120, // Fixed height for buttons
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

