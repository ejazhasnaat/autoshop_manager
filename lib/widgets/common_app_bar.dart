// lib/widgets/common_app_bar.dart
import 'package:autoshop_manager/features/settings/presentation/workshop_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  // Helper function to generate initials from a name
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name
        .trim()
        .split(RegExp(r'[\s-]+'))
        .where((part) => part.isNotEmpty);
    if (parts.length > 1) {
      return (parts.first.isNotEmpty ? parts.first[0] : '') +
          (parts.last.isNotEmpty ? parts.last[0] : '');
    } else if (parts.isNotEmpty) {
      final singleWord = parts.first;
      return singleWord.length > 1
          ? singleWord.substring(0, 2)
          : singleWord.substring(0, 1);
    }
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final shopSettingsAsync = ref.watch(workshopSettingsProvider);
    final theme = Theme.of(context);

    Widget leadingButton;
    if (showCloseButton) {
      leadingButton = IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close',
        onPressed: () => context.pop(),
      );
    } else if (showBackButton) {
      leadingButton = IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      );
    } else {
      leadingButton = IconButton(
        icon: const Icon(Icons.home_outlined),
        tooltip: 'Home',
        onPressed: () => context.go('/home'),
      );
    }

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // --- Left Section ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              leadingButton,
              if (title != null) ...[
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          // --- UPDATED: Center Section with Logo and Text ---
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png', // Using path from your baseline file
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.miscellaneous_services); // Fallback icon
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AutoManix',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Workshop Management System',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- UPDATED: Right Section with Workshop Info, User Initials, and Settings Icon ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customActions != null) ...customActions!,
              // Workshop Info
              shopSettingsAsync.when(
                data: (settings) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      settings.workshopName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      settings.workshopAddress,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              // User Initials
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _getInitials(authState.user?.fullName ?? '...').toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Settings Menu Button
              PopupMenuButton<String>(
                tooltip: 'Settings Menu',
                icon: const Icon(Icons.settings_outlined), // Using settings icon
                onSelected: (String result) async {
                  if (result == 'logout') {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  } else if (result == 'workshop_settings') {
                    context.push('/settings/workshop');
                  } else if (result == 'manage_users') {
                    context.go('/signup');
                  } else if (result == 'reminder_intervals') {
                    context.push('/reminders/intervals');
                  } else if (result == 'settings') {
                    context.push('/settings');
                  }
                },
                itemBuilder: (BuildContext context) {
                  final List<PopupMenuEntry<String>> menuItems = [];
                  if (authState.isAdmin) {
                    menuItems.addAll([
                      const PopupMenuItem<String>(
                        value: 'workshop_settings',
                        child: Text('Workshop Settings'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Text('App Settings'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'manage_users',
                        child: Text('Manage Users'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'reminder_intervals',
                        child: Text('Reminder Intervals'),
                      ),
                    ]);
                  }
                  menuItems.addAll([
                    if (authState.isAdmin) const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ]);
                  return menuItems;
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

