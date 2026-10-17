import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/providers/app_providers.dart';

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
  final String group;

  const AdminMenuItem({
    required this.section,
    required this.title,
    required this.icon,
    required this.route,
    required this.group,
  });
}

const List<AdminMenuItem> adminMenuItems = [
  // OVERVIEW
  AdminMenuItem(
    section: AdminMenuSection.dashboard,
    title: 'Dashboard',
    icon: Icons.grid_view_rounded,
    route: '/admin',
    group: 'OVERVIEW',
  ),
  AdminMenuItem(
    section: AdminMenuSection.orders,
    title: 'Customer Orders',
    icon: Icons.receipt_long_rounded,
    route: '/admin/orders',
    group: 'OVERVIEW',
  ),

  // STORES & CATALOG
  AdminMenuItem(
    section: AdminMenuSection.branches,
    title: 'Manage Branches',
    icon: Icons.storefront_rounded,
    route: '/admin/branches',
    group: 'STORES & CATALOG',
  ),
  AdminMenuItem(
    section: AdminMenuSection.vegetables,
    title: 'Manage Vegetables',
    icon: Icons.eco_rounded,
    route: '/admin/vegetables',
    group: 'STORES & CATALOG',
  ),
  AdminMenuItem(
    section: AdminMenuSection.categories,
    title: 'Categories',
    icon: Icons.category_rounded,
    route: '/admin/categories',
    group: 'STORES & CATALOG',
  ),
  AdminMenuItem(
    section: AdminMenuSection.inventory,
    title: 'Branch Inventory',
    icon: Icons.inventory_2_rounded,
    route: '/admin/inventory',
    group: 'STORES & CATALOG',
  ),

  // PRICING & PROMOTIONS
  AdminMenuItem(
    section: AdminMenuSection.prices,
    title: 'Price Management',
    icon: Icons.price_change_rounded,
    route: '/admin/prices',
    group: 'PRICING & OFFERS',
  ),
  AdminMenuItem(
    section: AdminMenuSection.promotions,
    title: 'Discounts & Promotions',
    icon: Icons.local_offer_rounded,
    route: '/admin/promotions',
    group: 'PRICING & OFFERS',
  ),

  // FLEET & OPERATIONS
  AdminMenuItem(
    section: AdminMenuSection.staff,
    title: 'Branch Staff',
    icon: Icons.badge_rounded,
    route: '/admin/staff',
    group: 'FLEET & STAFF',
  ),
  AdminMenuItem(
    section: AdminMenuSection.deliveryAgents,
    title: 'Delivery Agents',
    icon: Icons.delivery_dining_rounded,
    route: '/admin/delivery-agents',
    group: 'FLEET & STAFF',
  ),
  AdminMenuItem(
    section: AdminMenuSection.deliveryAssignments,
    title: 'Delivery Dispatch',
    icon: Icons.assignment_ind_rounded,
    route: '/admin/delivery-assignments',
    group: 'FLEET & STAFF',
  ),

  // ANALYTICS & SYSTEM
  AdminMenuItem(
    section: AdminMenuSection.reports,
    title: 'Sales Reports',
    icon: Icons.bar_chart_rounded,
    route: '/admin/reports',
    group: 'ANALYTICS & CONFIG',
  ),
  AdminMenuItem(
    section: AdminMenuSection.settings,
    title: 'Settings',
    icon: Icons.settings_rounded,
    route: '/admin/settings',
    group: 'ANALYTICS & CONFIG',
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
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vegora Admin',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Spacer(),
          ...?actions,
          const SizedBox(width: 14),
          // Live Network Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 3.5,
                  backgroundColor: Color(0xFF10B981),
                ),
                SizedBox(width: 6),
                Text(
                  'Network Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Super Admin profile pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: Color(0xFF0B6B3A),
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.storefront_rounded, size: 15),
            label: const Text('Storefront', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neutral800,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 19),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 250,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B6B3A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Operations Console',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Grouped Menu List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildGroupedNavList(context),
                ),
              ),
            ),

            // Footer Logout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  dense: true,
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 19,
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      fontSize: 13,
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

  List<Widget> _buildGroupedNavList(BuildContext context) {
    final widgets = <Widget>[];
    String? currentGroup;

    for (final item in adminMenuItems) {
      if (item.group != currentGroup) {
        currentGroup = item.group;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 14, bottom: 5),
            child: Text(
              currentGroup,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8), // Slate-400
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }
      widgets.add(_buildNavItem(context, item));
    }

    return widgets;
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0B6B3A)),
            accountName: const Text(
              'Vegora Admin Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('admin@vegora.in'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF0B6B3A),
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
            ? const Color(0xFFECFDF5) // Emerald-50
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFFF8FAFC),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            if (!isSelected) {
              context.go(item.route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: isSelected ? const Color(0xFF0B6B3A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0B6B3A) : const Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B6B3A),
                      shape: BoxShape.circle,
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
