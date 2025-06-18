// lib/widgets/common_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/core/constants/app_constants.dart'; // For appName
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart'; // For authNotifierProvider

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title; // Reverted to nullable title
  final bool showBackButton;
  final List<Widget>? customActions;

  const CommonAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.customActions, // Initialize customActions
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserName = authState.user?.username ?? 'Guest';

    // Default actions (username and settings)
    final List<Widget> defaultActions = [
      // Display active user name
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            currentUserName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      // Hamburger settings icon (using PopupMenuButton)
      PopupMenuButton<String>(
        icon: const Icon(Icons.settings),
        onSelected: (String result) async {
          if (result == 'logout') {
            await ref.read(authNotifierProvider.notifier).logout();
            context.go('/login');
          } else if (result == 'about') {
            showAboutDialog(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: '1.0.0', // Consider making this dynamic
              applicationLegalese:
                  '© 2023 Autoshop Manager. All rights reserved.',
            );
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'about', child: Text('About')),
          const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
        ],
      ),
      const SizedBox(width: 8.0), // Padding on the right
    ];

    // Combine custom actions with default actions
    List<Widget> combinedActions = [];
    if (customActions != null) {
      combinedActions.addAll(customActions!); // Add custom actions first
    }
    combinedActions.addAll(defaultActions); // Then add default actions

    return AppBar(
      title: Text(
        title ?? AppConstants.appName,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).appBarTheme.foregroundColor, // Use appBarTheme foregroundColor
        ),
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Use appBarTheme backgroundColor
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Use appBarTheme foregroundColor
      elevation: Theme.of(context).appBarTheme.elevation, // Use appBarTheme elevation
      shadowColor: Theme.of(context).appBarTheme.shadowColor, // Use appBarTheme shadowColor
      scrolledUnderElevation: Theme.of(context).appBarTheme.scrolledUnderElevation, // Use appBarTheme scrolledUnderElevation
      automaticallyImplyLeading: false, // Control leading behavior explicitly

      leading: showBackButton
          ? IconButton(
              // Show back button
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // Fallback: If cannot pop, go to home
                  context.go('/home');
                }
              },
            )
          : IconButton(
              // Show home icon if not showing back button
              icon: const Icon(Icons.home),
              onPressed: () {
                context.go('/home'); // Navigate to home
              },
            ),
      actions: combinedActions, // Use the combined actions list
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

