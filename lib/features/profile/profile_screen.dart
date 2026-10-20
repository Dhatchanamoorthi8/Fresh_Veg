import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../shared/models/user_role.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/auth_provider.dart';
import '../../app/router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerName = ref.watch(customerNameProvider);
    final customerPhone = ref.watch(customerPhoneProvider);
    final currentAddress = ref.watch(selectedAddressProvider);
    final authUser = ref.watch(currentSupabaseUserProvider);
    final activeLocale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          activeLocale.languageCode == 'ta' ? 'என் கணக்கு' : 'My Account',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Registered User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : '👤',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                customerName.isNotEmpty
                                    ? customerName
                                    : 'Registered Customer',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (authUser?.email != null &&
                            authUser!.email!.isNotEmpty)
                          Text(
                            authUser.email!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (customerPhone != null && customerPhone.isNotEmpty)
                          Text(
                            '+91 $customerPhone',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral700,
                            ),
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
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Staff & Administrator Portals (based on user role)
            if (ref.watch(userRoleProvider) == AppUserRole.superAdmin ||
                ref.watch(userRoleProvider) == AppUserRole.branchAdmin) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primaryDark,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Dashboard',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            'Sales KPIs, branches, inventory, stock & clearance',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => context.push('/admin'),
                      child: const Text('Open', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (ref.watch(userRoleProvider) == AppUserRole.branchStaff ||
                ref.watch(userRoleProvider) == AppUserRole.superAdmin) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.statusPreparing,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Staff Dashboard',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Process incoming orders, packing & ready for pickup',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusPreparing,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => context.push('/staff'),
                      child: const Text(
                        'Store',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (ref.watch(userRoleProvider) == AppUserRole.deliveryStaff ||
                ref.watch(userRoleProvider) == AppUserRole.superAdmin) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.statusDelivered,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Partner Portal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'View assigned deliveries and update status',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusDelivered,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => context.push('/delivery'),
                      child: const Text(
                        'Portal',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 10),

            // Profile Options Menu
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.language_rounded,
                      title: activeLocale.languageCode == 'ta'
                          ? 'மொழி / Language'
                          : 'Language / மொழி',
                      subtitle: activeLocale.languageCode == 'ta'
                          ? 'தமிழ் (Tamil) • செயலில் உள்ளது'
                          : 'English • Active',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          activeLocale.languageCode == 'ta'
                              ? 'தமிழ்'
                              : 'English',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => _showLanguageSelectionDialog(
                        context,
                        ref,
                        activeLocale,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.pin_drop_outlined,
                      title: 'Saved Delivery Addresses',
                      subtitle:
                          'Current: ${currentAddress.label} (${currentAddress.area})',
                      onTap: () => context.push('/branches'),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order History',
                      subtitle: 'Track past orders and receipts',
                      onTap: () => context.go('/orders'),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.storefront_outlined,
                      title: 'Explore 5+ City Store Hubs',
                      subtitle: 'View branch timings, coverage & addresses',
                      onTap: () => context.push('/branches'),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Preferences',
                      subtitle: 'Order updates and morning harvest alerts',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications simulated: Enabled'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & FAQ',
                      subtitle:
                          'Multi-branch ordering rules and delivery times',
                      onTap: () => _showHelpDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logout / Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCancelled,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  ref.read(customerNameProvider.notifier).setName('');
                  ref.read(customerPhoneProvider.notifier).setPhone(null);
                  ref.invalidate(userProfileProvider);
                  AppAuthListenable.instance.notify();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully signed out.')),
                    );
                    context.go('/login');
                  }
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingWidget,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing:
          trailingWidget ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
      onTap: onTap,
    );
  }

  void _showLanguageSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Language / மொழியைத் தேர்ந்தெடுக்கவும்',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Select your preferred app language',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: currentLocale.languageCode == 'en'
                          ? AppColors.primary
                          : AppColors.border,
                      width: currentLocale.languageCode == 'en' ? 1.5 : 1,
                    ),
                  ),
                  tileColor: currentLocale.languageCode == 'en'
                      ? AppColors.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  title: const Text(
                    'English',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Default interface language'),
                  trailing: currentLocale.languageCode == 'en'
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(appLocaleProvider.notifier)
                        .setLanguage('en');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language updated to English'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: currentLocale.languageCode == 'ta'
                          ? AppColors.primary
                          : AppColors.border,
                      width: currentLocale.languageCode == 'ta' ? 1.5 : 1,
                    ),
                  ),
                  tileColor: currentLocale.languageCode == 'ta'
                      ? AppColors.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      'த',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  title: const Text(
                    'தமிழ் (Tamil)',
                    style: TextStyle(fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  subtitle: const Text(
                    'முழுமையான தமிழ் இடைமுகம் மற்றும் காய்கறி பெயர்கள்',
                    style: TextStyle(fontSize: 11, height: 1.3),
                  ),
                  trailing: currentLocale.languageCode == 'ta'
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(appLocaleProvider.notifier)
                        .setLanguage('ta');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'செயலி மொழி தமிழில் மாற்றப்பட்டது (Tamil set)',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Multi-Branch Ordering Rules'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Orders are fulfilled from a single physical branch to guarantee 30-min freshness.',
            ),
            SizedBox(height: 8),
            Text('• Inventory and vegetable prices are branch-specific.'),
            SizedBox(height: 8),
            Text(
              '• If you change your delivery branch with an active cart, you will be prompted before the cart is cleared.',
            ),
            SizedBox(height: 8),
            Text('• Orders can be cancelled while in NEW or ACCEPTED status.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}
