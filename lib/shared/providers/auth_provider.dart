import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_address.dart';
import '../models/user_role.dart';
import '../repositories/supabase_auth_repository.dart';
import 'app_providers.dart';

/// Stream of Supabase Auth state changes
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Current authenticated Supabase User
final currentSupabaseUserProvider = Provider<User?>((ref) {
  ref.watch(authStateStreamProvider);
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
});

/// Current User Profile from database
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentSupabaseUserProvider);
  if (user == null) return null;
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getUserProfile(user.id);
});

/// Active user role strictly derived from verified database profile
final userRoleProvider = Provider<AppUserRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.value?.role ?? AppUserRole.customer;
});

/// Convenience role checks
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).isAdmin;
});

final isStaffProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).isStaff;
});

final isDeliveryProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).isDelivery;
});

/// Customer phone notifier
final customerPhoneProvider = NotifierProvider<CustomerPhoneNotifier, String?>(
  () {
    return CustomerPhoneNotifier();
  },
);

class CustomerPhoneNotifier extends Notifier<String?> {
  @override
  String? build() {
    final profile = ref.watch(userProfileProvider).value;
    if (profile?.phone != null && profile!.phone!.trim().isNotEmpty) {
      return profile.phone!.trim();
    }
    final user = ref.watch(currentSupabaseUserProvider);
    final metaPhone = user?.userMetadata?['phone'] as String? ?? user?.phone;
    if (metaPhone != null && metaPhone.trim().isNotEmpty) {
      return metaPhone.trim();
    }
    return null;
  }

  void setPhone(String? phone) {
    state = phone;
  }
}

/// Customer full name notifier
final customerNameProvider = NotifierProvider<CustomerNameNotifier, String>(() {
  return CustomerNameNotifier();
});

class CustomerNameNotifier extends Notifier<String> {
  @override
  String build() {
    final profile = ref.watch(userProfileProvider).value;
    if (profile != null &&
        profile.fullName.trim().isNotEmpty &&
        profile.fullName.trim() != 'Customer') {
      return profile.fullName.trim();
    }
    final user = ref.watch(currentSupabaseUserProvider);
    final metaName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    if (profile?.fullName.trim().isNotEmpty == true) {
      return profile!.fullName.trim();
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      final emailPrefix = user.email!.split('@').first.trim();
      if (emailPrefix.isNotEmpty) {
        return emailPrefix;
      }
    }
    return 'Customer';
  }

  void setName(String name) {
    state = name;
  }
}

/// Customer addresses from repository
final customerAddressesProvider = FutureProvider<List<CustomerAddress>>((
  ref,
) async {
  final branchRepo = ref.watch(branchRepositoryProvider);
  return branchRepo.getSavedAddresses();
});

/// Selected delivery address
final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, CustomerAddress>(() {
      return SelectedAddressNotifier();
    });

class SelectedAddressNotifier extends Notifier<CustomerAddress> {
  static const CustomerAddress defaultFallbackAddress = CustomerAddress(
    id: 'addr_default_blr',
    label: 'Home',
    fullAddress: '#42, 4th Cross, 100 Feet Road, Indiranagar',
    area: 'Indiranagar',
    landmark: 'Near Metro Station',
    pinCode: '560038',
    eligibleBranchId: 'branch_blr_01',
    isDefault: true,
  );

  @override
  CustomerAddress build() {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final addresses = addressesAsync.value;
    if (addresses != null && addresses.isNotEmpty) {
      return addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
    }
    return defaultFallbackAddress;
  }

  void setAddress(CustomerAddress address) {
    state = address;
  }
}
