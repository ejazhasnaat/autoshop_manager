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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              leadingButton,
              if (title != null) ...[
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.normal
                  ),
                ),
              ],
            ],
          ),
          Expanded(
            child: Center(
              child: shopSettingsAsync.when(
                data: (settings) => Text(
                  settings.workshopName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customActions != null) ...customActions!,
              PopupMenuButton<String>(
                tooltip: 'Settings Menu',
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
                  } else if (result == 'settings') { // UPDATE: Navigation for new settings screen
                    context.push('/settings');
                  }
                },
                itemBuilder: (BuildContext context) {
                  final List<PopupMenuEntry<String>> menuItems = [];
                  if (authState.isAdmin) {
                    menuItems.addAll([
                      const PopupMenuItem<String>(value: 'workshop_settings', child: Text('Workshop Settings')),
                      // UPDATE: Link to the new general settings screen
                      const PopupMenuItem<String>(value: 'settings', child: Text('App Settings')),
                      const PopupMenuItem<String>(value: 'manage_users', child: Text('Manage Users')),
                      const PopupMenuItem<String>(value: 'reminder_intervals', child: Text('Reminder Intervals')),
                    ]);
                  }
                  menuItems.addAll([
                    if(authState.isAdmin) const PopupMenuDivider(),
                    const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
                  ]);
                  return menuItems;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Text(
                        authState.user?.fullName ?? 'Guest',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.settings_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
