// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/login_screen.dart';
import 'package:autoshop_manager/features/auth/presentation/screens/signup_screen.dart';
import 'package:autoshop_manager/features/home/presentation/screens/home_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_list_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/customer_detail_screen.dart';
import 'package:autoshop_manager/features/customer/presentation/screens/add_edit_customer_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:autoshop_manager/features/inventory/presentation/screens/add_edit_inventory_item_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/orders_list_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/add_edit_order_screen.dart';
import 'package:autoshop_manager/features/order/presentation/screens/order_detail_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/service_list_screen.dart';
import 'package:autoshop_manager/features/service/presentation/screens/add_edit_service_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/vehicle_model_list_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/add_edit_vehicle_model_screen.dart';
import 'package:autoshop_manager/features/reports/presentation/screens/reports_screen.dart';
import 'package:autoshop_manager/features/settings/presentation/screens/settings_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import 'package:autoshop_manager/features/vehicle/presentation/screens/add_edit_vehicle_screen.dart';
import 'package:autoshop_manager/data/database/app_database.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
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
          builder: (context, state) => AddEditCustomerScreen(
            customerId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => CustomerDetailScreen(
            customerId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/vehicles',
      builder: (context, state) => const SizedBox(), 
      routes: [
        // --- ADDED: New route for adding a vehicle in "draft mode" ---
        GoRoute(
          path: 'add_draft',
          builder: (context, state) => const AddEditVehicleScreen(
            isDraftMode: true,
          ),
        ),
        GoRoute(
          path: 'add/:customerId', 
          builder: (context, state) => AddEditVehicleScreen(
            customerId: int.parse(state.pathParameters['customerId']!),
          ),
        ),
        GoRoute(
          path: 'edit/:id', 
          builder: (context, state) => AddEditVehicleScreen(
            vehicleId: int.parse(state.pathParameters['id']!),
            customerId: int.parse(state.uri.queryParameters['customerId']!),
          ),
        ),
        GoRoute(
          path: ':id', 
          builder: (context, state) => VehicleDetailScreen(
            vehicleId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ]
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
          builder: (context, state) => AddEditInventoryItemScreen(
            itemId: int.parse(state.pathParameters['id']!),
          ),
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
          path: ':id',
          builder: (context, state) => OrderDetailScreen(
            orderId: int.parse(state.pathParameters['id']!),
          ),
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
          builder: (context, state) => AddEditServiceScreen(
            serviceId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/vehicle_models',
      builder: (context, state) => const VehicleModelListScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddEditVehicleModelScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) => AddEditVehicleModelScreen(
            make: state.uri.queryParameters['make'],
            model: state.uri.queryParameters['model'],
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
