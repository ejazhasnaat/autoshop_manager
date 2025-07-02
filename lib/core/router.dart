// lib/core/router.dart
import 'package:autoshop_manager/core/setup_providers.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/initial_setup_screen.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/login_screen.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/signup_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/add_edit_customer_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_detail_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_list_screen.dart';
import 'package:autoshop_manager/features/home/presentation/screens/home_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/add_edit_inventory_item_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/add_edit_order_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/order_detail_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/orders_list_screen.dart';
import 'package:autoshop_manager/features/repair_job/presentation/screens/add_edit_repair_job_screen.dart';
import 'package:autoshop_manager/features/repair_job/presentation/screens/receipt_screen.dart';
import 'package:autoshop_manager/features/repair_job/presentation/screens/repair_job_list_screen.dart';
import 'package:autoshop_manager/features/reminders/presentation/screens/add_edit_template_screen.dart';
import 'package:autoshop_manager/features/reminders/presentation/screens/manage_templates_screen.dart';
import 'package:autoshop_manager/features/reminders/presentation/screens/reminder_intervals_screen.dart';
import 'package:autoshop_manager/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:autoshop_manager/features/reports/presentation/screens/reports_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/add_edit_service_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/service_list_screen.dart';
import 'package:autoshop_manager/features/settings/presentation/screens/settings_screen.dart';
import 'package:autoshop_manager/features/settings/presentation/screens/workshop_settings_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/add_edit_vehicle_model_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/add_edit_vehicle_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/vehicle_history_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/vehicle_model_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

final routerProvider = Provider<GoRouter>((ref) {
  final isSetupComplete = ref.watch(setupCompleteProvider);
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        GoRouterRefreshStream(ref.read(authNotifierProvider.notifier).stream),
    redirect: (context, state) {
      final onSetupScreen = state.matchedLocation == '/initial-setup';
      final onLoginScreen = state.matchedLocation == '/login';
      final isAuthenticated = authState.isAuthenticated;

      if (!isSetupComplete) {
        return onSetupScreen ? null : '/initial-setup';
      }

      if (onSetupScreen) return '/login';

      if (!isAuthenticated && !onLoginScreen) return '/login';

      if (isAuthenticated && onLoginScreen) return '/home';

      return null;
    },
    routes: [
      GoRoute(
          path: '/initial-setup',
          builder: (context, state) => const InitialSetupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListScreen(),
          routes: [
            GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditCustomerScreen()),
            GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AddEditCustomerScreen(
                    customerId: int.parse(state.pathParameters['id']!))),
            GoRoute(
                path: ':id',
                builder: (context, state) => CustomerDetailScreen(
                    customerId: int.parse(state.pathParameters['id']!)))
          ]),
      GoRoute(
          path: '/vehicles',
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
                path: 'add_draft',
                builder: (context, state) =>
                    const AddEditVehicleScreen(isDraftMode: true)),
            GoRoute(
                path: 'add/:customerId',
                builder: (context, state) => AddEditVehicleScreen(
                    customerId: int.parse(state.pathParameters['customerId']!))),
            GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AddEditVehicleScreen(
                    vehicleId: int.parse(state.pathParameters['id']!),
                    customerId:
                        int.parse(state.uri.queryParameters['customerId']!))),
            GoRoute(
                path: ':id',
                builder: (context, state) => VehicleDetailScreen(
                    vehicleId: int.parse(state.pathParameters['id']!)),
                // --- ADDED: Nested route for the vehicle history screen ---
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => VehicleHistoryScreen(
                      vehicleId: int.parse(state.pathParameters['id']!)
                    ),
                  )
                ]
            )
          ]),
      GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryListScreen(),
          routes: [
            GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const AddEditInventoryItemScreen()),
            GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AddEditInventoryItemScreen(
                    itemId: int.parse(state.pathParameters['id']!)))
          ]),
      GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersListScreen(),
          routes: [
            GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditOrderScreen()),
            GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailScreen(
                    orderId: int.parse(state.pathParameters['id']!)))
          ]),
      GoRoute(
          path: '/services',
          builder: (context, state) => const ServiceListScreen(),
          routes: [
            GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditServiceScreen()),
            GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AddEditServiceScreen(
                    serviceId: int.parse(state.pathParameters['id']!)))
          ]),
      GoRoute(
        path: '/repairs',
        builder: (context, state) => const RepairJobListScreen(),
        routes: [
          GoRoute(
              path: 'add',
              builder: (context, state) => AddEditRepairJobScreen()),
          GoRoute(
              path: 'edit/:id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return AddEditRepairJobScreen(repairJobId: id);
              },
              routes: [
                GoRoute(
                  path: 'receipt',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    return ReceiptScreen(repairJobId: id!);
                  },
                ),
              ]),
        ],
      ),
      GoRoute(
          path: '/vehicle_models',
          builder: (context, state) => const VehicleModelListScreen(),
          routes: [
            GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const AddEditVehicleModelScreen()),
            GoRoute(
                path: 'edit',
                builder: (context, state) => AddEditVehicleModelScreen(
                    make: state.uri.queryParameters['make'],
                    model: state.uri.queryParameters['model']))
          ]),
      GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/settings/workshop',
          builder: (context, state) => const WorkshopSettingsScreen()),
      GoRoute(
        path: '/reminders',
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          final fromCustomerList =
              state.uri.queryParameters['fromCustomerList'] == 'true';
          return RemindersScreen(
            customerId: customerId != null ? int.tryParse(customerId) : null,
            showCloseButton: fromCustomerList,
          );
        },
        routes: [
          GoRoute(
              path: 'manage-templates',
              builder: (context, state) => const ManageTemplatesScreen(),
              routes: [
                GoRoute(
                    path: 'add',
                    builder: (context, state) =>
                        const AddEditTemplateScreen()),
                GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        AddEditTemplateScreen(template: state.extra as MessageTemplate))
              ]),
          GoRoute(
              path: 'intervals',
              builder: (context, state) => const ReminderIntervalsScreen()),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

