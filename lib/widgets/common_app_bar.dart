// lib/widgets/common_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/core/constants/app_constants.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showCloseButton;
  final List<Widget>? customActions;
  final PreferredSizeWidget? bottom;

  const CommonAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.showCloseButton = false,
    this.customActions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserName = authState.user?.username ?? 'Guest';

    final List<Widget> defaultActions = [
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
      PopupMenuButton<String>(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings Menu',
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
          } else if (result == 'manage_users') {
            context.go('/signup');
          } 
          else if (result == 'reminder_intervals') {
            // --- FIX: Changed context.go to context.push to preserve the navigation stack ---
            context.push('/reminders/intervals');
          }
        },
        itemBuilder: (BuildContext context) {
          final List<PopupMenuEntry<String>> menuItems = [
            const PopupMenuItem<String>(value: 'about', child: Text('About')),
            const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
          ];

          if (authState.isAdmin) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'manage_users',
                child: Text('Manage Users'),
              ),
            );
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'reminder_intervals',
                child: Text('Reminder Intervals'),
              ),
            );
          }

          menuItems.addAll([
            const PopupMenuDivider(),
            const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
          ]);

          return menuItems;
        },
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

      leading: showCloseButton
          ? IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => context.pop(),
            )
          : showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
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
                  tooltip: 'Home',
                  onPressed: () {
                    context.go('/home');
                  },
                ),
      actions: combinedActions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
