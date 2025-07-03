// lib/features/about/presentation/screens/about_screen.dart
import 'package:flutter/material.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // You can replace this with a dynamic version later if needed
    const String appVersion = '1.0.0';

    return AlertDialog(
      title: const Text('About AutoManix'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'AutoManix',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $appVersion',
              style: textTheme.titleSmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            // --- FIX: Added the new slogan ---
            Text(
              '"Shift Your Workshop into Auto Mode."',
              style: textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Your comprehensive workshop management solution, designed to streamline operations, manage customers, and track repair jobs efficiently.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              '© 2025 Your Company Name. All Rights Reserved.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

