// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/auth/presentation/auth_providers.dart'; // For AuthState and authNotifierProvider
import 'package:autoshop_manager/features/auth/presentation/screens/login_screen.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/signup_screen.dart';
import 'package:autoshop_manager/features/home/presentation/screens/home_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_list_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/add_edit_customer_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_detail_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/add_edit_inventory_item_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/orders_list_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/add_edit_order_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/order_detail_screen.dart';
import 'package:autoshop_manager/features/report/presentation/screens/reports_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/service_list_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/add_edit_service_screen.dart';
import 'package:autoshop_manager/features/vehicle_model/presentation/screens/vehicle_model_list_screen.dart'; // <--- NEW IMPORT
import 'package:autoshop_manager/features/vehicle_model/presentation/screens/add_edit_vehicle_model_screen.dart'; // <--- NEW IMPORT
import 'package:state_notifier/state_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/home' : '/login',
    refreshListenable: GoRouterRefreshStream(ref.watch(authNotifierProvider.notifier)),
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      if (!isLoggedIn) {
        return loggingIn || signingUp ? null : '/login';
      }

      if (isLoggedIn && (loggingIn || signingUp)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditCustomerScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final customerId = int.parse(state.pathParameters['id']!);
              return AddEditCustomerScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: ':customerId',
            builder: (context, state) {
              final customerId = int.parse(state.pathParameters['customerId']!);
              return CustomerDetailScreen(customerId: customerId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditInventoryItemScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final itemId = int.parse(state.pathParameters['id']!);
              return AddEditInventoryItemScreen(itemId: itemId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditOrderScreen(),
          ),
          GoRoute(
            path: ':orderId',
            builder: (context, state) {
              final orderId = int.parse(state.pathParameters['orderId']!);
              return OrderDetailScreen(orderId: orderId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServiceListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditServiceScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final serviceId = int.parse(state.pathParameters['id']!);
              return AddEditServiceScreen(serviceId: serviceId);
            },
          ),
        ],
      ),
      // <--- NEW ROUTES for Vehicle Models (replacing placeholder) --->
      GoRoute(
        path: '/vehicle_models',
        builder: (context, state) => const VehicleModelListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditVehicleModelScreen(),
          ),
          GoRoute( // Route for editing using composite key (make, model)
            path: 'edit/:make/:model',
            builder: (context, state) {
              final make = state.pathParameters['make']!;
              final model = state.pathParameters['model']!;
              return AddEditVehicleModelScreen(make: make, model: model);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  final StateNotifier<AuthState> _authNotifier;
  late final VoidCallback _disposer;

  GoRouterRefreshStream(this._authNotifier) {
    _disposer = _authNotifier.addListener((state) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposer();
    super.dispose();
  }
}

