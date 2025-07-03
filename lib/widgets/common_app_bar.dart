// lib/widgets/common_app_bar.dart
import 'package:autoshop_manager/features/about/presentation/screens/about_screen.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final shopSettingsAsync = ref.watch(shopSettingsProvider);
    final theme = Theme.of(context);

    Widget leadingButton;
    if (showCloseButton) {
      leadingButton = IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.miscellaneous_services);
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customActions != null) ...customActions!,
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
              PopupMenuButton<String>(
                tooltip: 'Options',
                icon: const Icon(Icons.menu),
                onSelected: (String result) async {
                  if (result == 'logout') {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  } else if (result == 'close') {
                    SystemNavigator.pop();
                  } else if (result == 'about') {
                    showDialog(
                      context: context,
                      builder: (_) => const AppAboutDialog(),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'close',
                      child: Text('Close App'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'about',
                      child: Text('About'),
                    ),
                  ];
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

