import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/admin/admin_branches_screen.dart';
import '../features/admin/admin_categories_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_delivery_agents_screen.dart';
import '../features/admin/admin_delivery_assignments_screen.dart';
import '../features/admin/admin_inventory_screen.dart';
import '../features/admin/admin_orders_screen.dart';
import '../features/admin/admin_price_management_screen.dart';
import '../features/admin/admin_promotions_screen.dart';
import '../features/admin/admin_reports_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/admin/admin_staff_management_screen.dart';
import '../features/admin/admin_vegetables_screen.dart';
import '../features/auth/admin_login_screen.dart';
import '../features/auth/staff_login_screen.dart';
import '../features/branch_staff/branch_staff_screen.dart';

final GlobalKey<NavigatorState> _adminNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminRoot');

final adminRouter = GoRouter(
  navigatorKey: _adminNavigatorKey,
  initialLocation: '/admin',
  redirect: (context, state) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = user != null;
      final loc = state.matchedLocation;

      final isAuthScreen = loc == '/admin/login' || loc == '/staff/login';
      if (!isAuthenticated && !isAuthScreen) {
        return '/admin/login';
      }
    } catch (_) {}
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/admin',
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      redirect: (context, state) => '/admin',
    ),
    GoRoute(
      path: '/admin/branches',
      builder: (context, state) => const AdminBranchesScreen(),
    ),
    GoRoute(
      path: '/admin/vegetables',
      builder: (context, state) => const AdminVegetablesScreen(),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesScreen(),
    ),
    GoRoute(
      path: '/admin/inventory',
      builder: (context, state) => const AdminInventoryScreen(),
    ),
    GoRoute(
      path: '/admin/prices',
      builder: (context, state) => const AdminPriceManagementScreen(),
    ),
    GoRoute(
      path: '/admin/promotions',
      builder: (context, state) => const AdminPromotionsScreen(),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      path: '/admin/staff',
      builder: (context, state) => const AdminStaffManagementScreen(),
    ),
    GoRoute(
      path: '/admin/delivery-agents',
      builder: (context, state) => const AdminDeliveryAgentsScreen(),
    ),
    GoRoute(
      path: '/admin/delivery-assignments',
      builder: (context, state) => const AdminDeliveryAssignmentsScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),

    // Branch Staff Workflows
    GoRoute(
      path: '/staff/login',
      builder: (context, state) => const StaffLoginScreen(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const BranchStaffScreen(),
    ),
    GoRoute(
      path: '/staff/dashboard',
      redirect: (context, state) => '/staff',
    ),
  ],
);
