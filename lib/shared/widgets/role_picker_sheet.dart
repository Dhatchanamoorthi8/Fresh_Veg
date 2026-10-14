import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';

class RoleIndicatorBadge extends ConsumerWidget {
  const RoleIndicatorBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;

    return InkWell(
      onTap: () => showRoleInfoSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: role.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: role.color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role.icon, size: 14, color: role.color),
            const SizedBox(width: 5),
            Text(
              profile != null &&
                      role == AppUserRole.branchStaff &&
                      profile.branchId != null
                  ? 'Store Staff'
                  : role.displayName,
              style: TextStyle(
                color: role.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.shield_outlined, size: 13, color: role.color),
          ],
        ),
      ),
    );
  }
}

void showRoleInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const RoleInfoSheet(),
  );
}

class RoleInfoSheet extends ConsumerWidget {
  const RoleInfoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userRoleProvider);
    final authUser = ref.watch(currentSupabaseUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentRole.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentRole.icon,
                    color: currentRole.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentRole.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authUser?.email ?? 'Verified Account',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (profile?.isActive ?? true)
                        ? AppColors.primaryContainer
                        : AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (profile?.isActive ?? true) ? 'Active' : 'Suspended',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: (profile?.isActive ?? true)
                          ? AppColors.primaryDark
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 20,
                    color: AppColors.neutral700,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Access levels and administrative roles are securely enforced by Supabase Row Level Security (RLS).',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Switch Authentication Portal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildPortalTile(
              context: context,
              icon: Icons.shopping_basket_rounded,
              title: 'Customer Storefront',
              subtitle: 'Shop fresh greens and track personal orders',
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            const SizedBox(height: 8),
            _buildPortalTile(
              context: context,
              icon: Icons.storefront_rounded,
              title: 'Store Staff Portal',
              subtitle: 'Order packing and branch inventory',
              onTap: () {
                Navigator.pop(context);
                context.push('/staff/login');
              },
            ),
            const SizedBox(height: 8),
            _buildPortalTile(
              context: context,
              icon: Icons.delivery_dining_rounded,
              title: 'Delivery Partner Portal',
              subtitle: 'Route pickups and live delivery drops',
              onTap: () {
                Navigator.pop(context);
                context.push('/delivery/login');
              },
            ),
            const SizedBox(height: 8),
            _buildPortalTile(
              context: context,
              icon: Icons.admin_panel_settings_rounded,
              title: 'Administrator Console',
              subtitle: 'Branch network, staff control and financial KPIs',
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/login');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
