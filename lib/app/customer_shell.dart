import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/app_locale_state.dart';
import '../shared/providers/cart_provider.dart';

class CustomerShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: isTamil ? 'முகப்பு' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              activeIcon: const Icon(Icons.search_rounded),
              label: isTamil ? 'பட்டியல்' : 'Catalog',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.totalItemCount}'),
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                child: const Icon(Icons.shopping_basket_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.totalItemCount}'),
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                child: const Icon(Icons.shopping_basket_rounded),
              ),
              label: isTamil ? 'கூடை' : 'Cart',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: isTamil ? 'ஆர்டர்கள்' : 'Orders',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: isTamil ? 'சுயவிவரம்' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
