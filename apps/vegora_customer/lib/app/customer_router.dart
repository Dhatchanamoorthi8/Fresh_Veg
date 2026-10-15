import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vegora_models/vegora_models.dart';

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
import '../features/home/home_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import 'customer_shell.dart';

/// Listenable that notifies GoRouter whenever the Supabase authentication
/// session changes (sign in, sign out, token refresh).
class CustomerAuthListenable extends ChangeNotifier {
  static final CustomerAuthListenable instance = CustomerAuthListenable._();
  CustomerAuthListenable._() {
    _trySubscribe();
  }

  StreamSubscription<AuthState>? _sub;

  void _trySubscribe() {
    if (_sub != null) return;
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        notifyListeners();
      });
    } catch (_) {
      // Supabase uninitialized yet
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

final customerRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: CustomerAuthListenable.instance,
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
      // Redirect away from splash or auth forms directly to the storefront home.
      if (isAuthenticated) {
        if (loc == '/' || isAuthRoute) {
          return '/home';
        }
      }

      // 2. Unauthenticated users:
      // Protect private customer accounts: profile, orders, checkout, tracking
      final isProtected =
          loc == '/profile' ||
          loc == '/orders' ||
          loc == '/checkout' ||
          loc == '/order-confirmation' ||
          loc.startsWith('/tracking/');

      if (!isAuthenticated && isProtected) {
        return '/login';
      }
    } catch (_) {
      // Supabase uninitialized in testing mode
    }
    return null;
  },
  routes: [
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Customer Authentication
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

    // Store & Catalog
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
      builder: (context, state) => const CheckoutScreen(),
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

    // Bottom Navigation Shell for Customer
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CustomerShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCatalog,
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const CatalogScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCart,
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorOrders,
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
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
