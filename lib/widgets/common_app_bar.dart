// lib/widgets/common_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/core/constants/app_constants.dart'; // For appName
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart'; // For authNotifierProvider

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? customActions;
  final PreferredSizeWidget? bottom; // <--- NEW: Added bottom property

  const CommonAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.customActions,
    this.bottom, // Initialize bottom
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
      // Hamburger settings icon (using PopupMenuButton for now)
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
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2023 Autoshop Manager. All rights reserved.',
            );
          } else if (result == 'settings') {
            context.go('/settings');
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'about', child: Text('About')),
          const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
          const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
        ],
      ),
      const SizedBox(width: 8.0),
    ];

    List<Widget> combinedActions = [];
    if (customActions != null) {
      combinedActions.addAll(customActions!);
    }
    combinedActions.addAll(defaultActions);

    return AppBar(
      title: Text(
        title ?? AppConstants.appName,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
      scrolledUnderElevation: 8,
      automaticallyImplyLeading: false,

      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                context.go('/home');
              },
            ),
      actions: combinedActions,
      bottom: bottom, // <--- NEW: Use the passed bottom widget
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)); // Adjust preferred size if bottom is present
}

