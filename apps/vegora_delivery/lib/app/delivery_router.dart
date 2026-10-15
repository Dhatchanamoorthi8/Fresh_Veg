import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/delivery_login_screen.dart';
import '../features/delivery/delivery_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'deliveryRoot',
);

final deliveryRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/delivery',
  redirect: (context, state) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = user != null;
      final isLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLogin) {
        return '/login';
      }
      if (isAuthenticated && isLogin) {
        return '/delivery';
      }
    } catch (_) {}
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const DeliveryLoginScreen(),
    ),
    GoRoute(
      path: '/delivery',
      builder: (context, state) => const DeliveryScreen(),
    ),
  ],
);
