// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/core/router.dart'; // Your GoRouter configuration
import 'package:autoshop_manager/config/app_theme.dart'; // <--- NEW IMPORT

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider); // Assuming goRouterProvider is in core/router.dart
    
    return MaterialApp.router(
      title: 'Autoshop Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(), // <--- Use the theme from AppTheme class
      routerConfig: router,
    );
  }
}

