import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppUserRole {
  customer,
  branchStaff,
  deliveryStaff,
  branchAdmin,
  superAdmin;

  static AppUserRole fromDb(String? role) {
    switch (role) {
      case 'super_admin':
        return AppUserRole.superAdmin;
      case 'branch_admin':
        return AppUserRole.branchAdmin;
      case 'branch_staff':
        return AppUserRole.branchStaff;
      case 'delivery_staff':
        return AppUserRole.deliveryStaff;
      case 'customer':
      default:
        return AppUserRole.customer;
    }
  }

  String toDb() {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'super_admin';
      case AppUserRole.branchAdmin:
        return 'branch_admin';
      case AppUserRole.branchStaff:
        return 'branch_staff';
      case AppUserRole.deliveryStaff:
        return 'delivery_staff';
      case AppUserRole.customer:
        return 'customer';
    }
  }

  bool get isAdmin =>
      this == AppUserRole.superAdmin || this == AppUserRole.branchAdmin;
  bool get isStaff =>
      this == AppUserRole.branchStaff ||
      this == AppUserRole.branchAdmin ||
      this == AppUserRole.superAdmin;
  bool get isDelivery => this == AppUserRole.deliveryStaff;
}

extension AppUserRoleExtension on AppUserRole {
  String get displayName {
    switch (this) {
      case AppUserRole.customer:
        return 'Customer';
      case AppUserRole.branchStaff:
        return 'Branch Staff';
      case AppUserRole.deliveryStaff:
        return 'Delivery Partner';
      case AppUserRole.branchAdmin:
        return 'Branch Manager';
      case AppUserRole.superAdmin:
        return 'Platform Admin';
    }
  }

  String get shortDescription {
    switch (this) {
      case AppUserRole.customer:
        return 'Browse veggies, pick branch, order & track';
      case AppUserRole.branchStaff:
        return 'Accept orders, pack items & prepare for pickup';
      case AppUserRole.deliveryStaff:
        return 'Deliver assigned orders to customer doorstep';
      case AppUserRole.branchAdmin:
        return 'Manage branch inventory, pricing & assignments';
      case AppUserRole.superAdmin:
        return 'Full control over branches, catalog, reports & promotions';
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserRole.customer:
        return Icons.shopping_basket_rounded;
      case AppUserRole.branchStaff:
        return Icons.storefront_rounded;
      case AppUserRole.deliveryStaff:
        return Icons.delivery_dining_rounded;
      case AppUserRole.branchAdmin:
        return Icons.admin_panel_settings_rounded;
      case AppUserRole.superAdmin:
        return Icons.dashboard_customize_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AppUserRole.customer:
        return AppColors.primary;
      case AppUserRole.branchStaff:
        return AppColors.statusPreparing;
      case AppUserRole.deliveryStaff:
        return AppColors.statusOutForDelivery;
      case AppUserRole.branchAdmin:
        return const Color(0xFFD97706);
      case AppUserRole.superAdmin:
        return const Color(0xFF7C3AED);
    }
  }
}
