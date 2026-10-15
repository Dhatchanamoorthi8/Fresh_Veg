import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

enum AdminMenuSection {
  dashboard,
  branches,
  vegetables,
  categories,
  inventory,
  prices,
  promotions,
  orders,
  staff,
  deliveryAgents,
  deliveryAssignments,
  reports,
  settings,
}

class AdminMenuItem {
  final AdminMenuSection section;
  final String title;
  final IconData icon;
  final String route;

  const AdminMenuItem({
    required this.section,
    required this.title,
    required this.icon,
    required this.route,
  });
}

const List<AdminMenuItem> adminMenuItems = [
  AdminMenuItem(
    section: AdminMenuSection.dashboard,
    title: 'Dashboard',
    icon: Icons.dashboard_rounded,
    route: '/admin',
  ),
  AdminMenuItem(
    section: AdminMenuSection.branches,
    title: 'Manage Branches',
    icon: Icons.store_rounded,
    route: '/admin/branches',
  ),
  AdminMenuItem(
    section: AdminMenuSection.vegetables,
    title: 'Manage Vegetables',
    icon: Icons.eco_rounded,
    route: '/admin/vegetables',
  ),
  AdminMenuItem(
    section: AdminMenuSection.categories,
    title: 'Categories',
    icon: Icons.category_rounded,
    route: '/admin/categories',
  ),
  AdminMenuItem(
    section: AdminMenuSection.inventory,
    title: 'Branch Inventory',
    icon: Icons.inventory_2_rounded,
    route: '/admin/inventory',
  ),
  AdminMenuItem(
    section: AdminMenuSection.prices,
    title: 'Price Management',
    icon: Icons.price_change_rounded,
    route: '/admin/prices',
  ),
  AdminMenuItem(
    section: AdminMenuSection.promotions,
    title: 'Discounts & Promotions',
    icon: Icons.local_offer_rounded,
    route: '/admin/promotions',
  ),
  AdminMenuItem(
    section: AdminMenuSection.orders,
    title: 'Customer Orders',
    icon: Icons.receipt_long_rounded,
    route: '/admin/orders',
  ),
  AdminMenuItem(
    section: AdminMenuSection.staff,
    title: 'Branch Staff',
    icon: Icons.badge_rounded,
    route: '/admin/staff',
  ),
  AdminMenuItem(
    section: AdminMenuSection.deliveryAgents,
    title: 'Delivery Agents',
    icon: Icons.delivery_dining_rounded,
    route: '/admin/delivery-agents',
  ),
  AdminMenuItem(
    section: AdminMenuSection.deliveryAssignments,
    title: 'Delivery Assignments',
    icon: Icons.assignment_ind_rounded,
    route: '/admin/delivery-assignments',
  ),
  AdminMenuItem(
    section: AdminMenuSection.reports,
    title: 'Sales Reports',
    icon: Icons.bar_chart_rounded,
    route: '/admin/reports',
  ),
  AdminMenuItem(
    section: AdminMenuSection.settings,
    title: 'Settings',
    icon: Icons.settings_rounded,
    route: '/admin/settings',
  ),
];

class AdminScaffold extends ConsumerWidget {
  final AdminMenuSection currentSection;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.currentSection,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out of Admin Console?'),
        content: const Text(
          'Are you sure you want to log out of the Vegora administrative portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go('/admin/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.surface,
              elevation: 1,
              actions: [
                ...?actions,
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.neutral700,
                  ),
                  tooltip: 'Logout',
                  onPressed: () => _handleLogout(context, ref),
                ),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(context, ref),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, ref),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopTopBar(context, ref),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const Spacer(),
          ...?actions,
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.storefront_rounded,
              color: AppColors.neutral700,
            ),
            tooltip: 'View Customer Storefront',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.neutral200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/branding/vegora_app_icon.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Vegora',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Operations Portal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    for (final item in adminMenuItems)
                      _buildNavItem(context, item),
                  ],
                ),
              ),
            ),

            // Logout Item at bottom
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.neutral200, width: 1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () => _handleLogout(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: const Text(
              'Vegora Admin Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('admin@vegora.in'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                for (final item in adminMenuItems)
                  _buildNavItem(context, item, isDrawer: true),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Switch to Customer Store'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout(context, ref);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AdminMenuItem item, {
    bool isDrawer = false,
  }) {
    final isSelected = item.section == currentSection;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            if (!isSelected) {
              context.go(item.route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.neutral700,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutral800,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
