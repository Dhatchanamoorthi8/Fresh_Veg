import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vegora_admin_web/vegora_admin_web.dart';

import '../features/auth/delivery_login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/branches/branch_selection_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/product_details_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/order_confirmation_screen.dart';
import '../features/delivery/delivery_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/models/order.dart';
import '../shared/models/user_role.dart';
import 'customer_shell.dart';

/// Listenable that notifies GoRouter whenever the Supabase authentication
/// session changes (sign in, sign out, token refresh).
class AppAuthListenable extends ChangeNotifier {
  static final AppAuthListenable instance = AppAuthListenable._();
  AppAuthListenable._() {
    _trySubscribe();
  }

  StreamSubscription<AuthState>? _sub;
  bool isPasswordRecovery = false;
  AppUserRole currentRole = AppUserRole.customer;

  void setRole(AppUserRole role) {
    if (currentRole != role) {
      currentRole = role;
      notifyListeners();
    }
  }

  void _trySubscribe() {
    if (_sub != null) return;
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((
        data,
      ) async {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          isPasswordRecovery = true;
          appRouter.go('/customer/reset-password');
        } else if (data.session?.user != null) {
          _fetchAndSetRole(data.session!.user.id);
        } else {
          currentRole = AppUserRole.customer;
        }
        notifyListeners();
      });
    } catch (_) {
      // Supabase uninitialized yet
    }
  }

  Future<void> _fetchAndSetRole(String userId) async {
    try {
      final rolesRes = await Supabase.instance.client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roleList = (rolesRes as List)
          .map((r) => r['role'] as String?)
          .whereType<String>()
          .toList();

      if (roleList.contains('delivery_staff')) {
        currentRole = AppUserRole.deliveryStaff;
      } else if (roleList.contains('branch_staff')) {
        currentRole = AppUserRole.branchStaff;
      } else if (roleList.contains('super_admin')) {
        currentRole = AppUserRole.superAdmin;
      } else if (roleList.contains('branch_admin')) {
        currentRole = AppUserRole.branchAdmin;
      } else {
        currentRole = AppUserRole.customer;
      }
      notifyListeners();
    } catch (_) {
      // Supabase uninitialized or offline
    }
  }

  void initialize() {
    _trySubscribe();
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorHome = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final GlobalKey<NavigatorState> _shellNavigatorCatalog =
    GlobalKey<NavigatorState>(debugLabel: 'shellCatalog');
final GlobalKey<NavigatorState> _shellNavigatorCart = GlobalKey<NavigatorState>(
  debugLabel: 'shellCart',
);
final GlobalKey<NavigatorState> _shellNavigatorOrders =
    GlobalKey<NavigatorState>(debugLabel: 'shellOrders');
final GlobalKey<NavigatorState> _shellNavigatorProfile =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: AppAuthListenable.instance,
  redirect: (context, state) {
    try {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = supabaseUser != null;
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == '/login' ||
          loc == '/customer/login' ||
          loc == '/customer/register' ||
          loc == '/customer/forgot-password' ||
          loc == '/customer/reset-password';

      // 1. Authenticated users:
      if (isAuthenticated) {
        if (AppAuthListenable.instance.isPasswordRecovery ||
            loc == '/customer/reset-password' ||
            loc == '/admin/reset-password') {
          return null;
        }
        if (loc == '/' || isAuthRoute) {
          final role = AppAuthListenable.instance.currentRole;
          switch (role) {
            case AppUserRole.deliveryStaff:
              return '/delivery';
            case AppUserRole.branchStaff:
              return '/staff';
            case AppUserRole.superAdmin:
              return '/admin';
            case AppUserRole.branchAdmin:
            case AppUserRole.customer:
              return '/home';
          }
        }
      }

      final isPublicAuth =
          loc == '/' ||
          loc == '/admin/login' ||
          loc == '/admin/forgot-password' ||
          loc == '/admin/reset-password' ||
          loc == '/staff/login' ||
          loc == '/delivery/login' ||
          loc == '/branches';

      // Guard customer shopping & account operations: require authentication
      if (!isAuthenticated && !isPublicAuth && !isAuthRoute) {
        return '/login';
      }
    } catch (_) {
      // Supabase uninitialized (e.g. in standalone unit/widget tests)
    }
    return null;
  },
  routes: [
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Customer Authentication Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/customer/login',
      redirect: (context, state) => '/login',
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/customer/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/customer/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/customer/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // Dedicated Role Portals
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/forgot-password',
      builder: (context, state) => const AdminForgotPasswordScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/reset-password',
      builder: (context, state) => const AdminResetPasswordScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/dashboard',
      redirect: (context, state) => '/admin',
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/branches',
      builder: (context, state) => const AdminBranchesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/vegetables',
      builder: (context, state) => const AdminVegetablesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/inventory',
      builder: (context, state) => const AdminInventoryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/prices',
      builder: (context, state) => const AdminPriceManagementScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/promotions',
      builder: (context, state) => const AdminPromotionsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/orders',
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/staff',
      builder: (context, state) => const AdminStaffManagementScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/delivery-agents',
      builder: (context, state) => const AdminDeliveryAgentsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/delivery-assignments',
      builder: (context, state) => const AdminDeliveryAssignmentsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),

    // Branch Staff Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/staff/login',
      builder: (context, state) => const StaffLoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/staff',
      builder: (context, state) => const BranchStaffScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/staff/dashboard',
      redirect: (context, state) => '/staff',
    ),

    // Delivery Partner Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/delivery/login',
      builder: (context, state) => const DeliveryLoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/delivery',
      builder: (context, state) => const DeliveryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/delivery/dashboard',
      redirect: (context, state) => '/delivery',
    ),

    // Store & Catalog Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/branches',
      builder: (context, state) => const BranchSelectionScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailsScreen(productId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/checkout',
      builder: (context, state) {
        final instructions = state.extra as String?;
        return CheckoutScreen(initialInstructions: instructions);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/order-confirmation',
      builder: (context, state) {
        final order = state.extra as Order;
        return OrderConfirmationScreen(order: order);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tracking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderTrackingScreen(orderId: id);
      },
    ),

    // Bottom Navigation Shell for Customer Storefront
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return CustomerShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1: Catalog / Search
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCatalog,
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) {
                final categoryId = state.uri.queryParameters['categoryId'];
                return CatalogScreen(initialCategoryId: categoryId);
              },
            ),
          ],
        ),

        // Tab 2: Cart
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCart,
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),

        // Tab 3: Orders
        StatefulShellBranch(
          navigatorKey: _shellNavigatorOrders,
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),

        // Tab 4: Profile
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfile,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
