import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vegora_models/vegora_models.dart';

class UserProfile {
  final String id;
  final String? phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isActive;
  final AppUserRole role;
  final String? branchId;

  const UserProfile({
    required this.id,
    this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.isActive = true,
    this.role = AppUserRole.customer,
    this.branchId,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    AppUserRole? role,
    String? branchId,
  }) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String? ?? 'Customer',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      role:
          role ??
          (json['role'] != null
              ? AppUserRole.fromDb(json['role'] as String?)
              : AppUserRole.customer),
      branchId: branchId ?? json['branch_id'] as String?,
    );
  }
}

class SupabaseAuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register a new customer account with Name, Email & Password
  /// Strict security: All public signups are assigned 'customer' role.
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final cleanPhone = phone?.replaceAll(RegExp(r'\s+|-'), '');
    final formattedPhone = cleanPhone != null && cleanPhone.isNotEmpty
        ? (cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone')
        : null;

    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'phone': ?formattedPhone},
    );
  }

  /// Convenient alias for customer signup
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return signUpWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  /// Google OAuth Sign-In via Supabase Auth
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.kisanfresh://login-callback',
    );
  }

  /// Real Supabase Password Reset Email
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo:
          redirectTo ??
          (kIsWeb ? null : 'io.supabase.kisanfresh://reset-callback'),
    );
  }

  /// Verify Recovery OTP or Token (supports 6-digit code, token string, or pasted URL)
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    String cleanToken = token.trim();
    if (cleanToken.contains('token=')) {
      final uri = Uri.tryParse(cleanToken);
      if (uri != null && uri.queryParameters.containsKey('token')) {
        cleanToken = uri.queryParameters['token']!;
      } else {
        final match = RegExp(r'[?&#]token=([^&#]+)').firstMatch(cleanToken);
        if (match != null) {
          cleanToken = Uri.decodeComponent(match.group(1)!);
        }
      }
    }
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: cleanToken,
      type: OtpType.recovery,
    );
  }

  /// Update User Password (used after opening recovery link)
  Future<UserResponse> updateUserPassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Retrieve User Profile from `public.profiles`
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;

      final rolesRes = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roleList = (rolesRes as List)
          .map((r) => r['role'] as String?)
          .whereType<String>()
          .toList();

      AppUserRole role = AppUserRole.customer;
      if (roleList.contains('super_admin')) {
        role = AppUserRole.superAdmin;
      } else if (roleList.contains('branch_admin')) {
        role = AppUserRole.branchAdmin;
      } else if (roleList.contains('branch_staff')) {
        role = AppUserRole.branchStaff;
      } else if (roleList.contains('delivery_staff')) {
        role = AppUserRole.deliveryStaff;
      }

      final branchId = await getStaffBranchId(userId);

      return UserProfile.fromJson(res, role: role, branchId: branchId);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update User Profile details
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    String? email,
  }) async {
    await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          if (email != null && email.isNotEmpty) 'email': email,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Ensures user profile is synced from authenticated user session metadata
  Future<void> syncCustomerSession(User user) async {
    try {
      final metadataName =
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email?.split('@').first ??
          'Customer';
      final avatarUrl =
          user.userMetadata?['avatar_url'] as String? ??
          user.userMetadata?['picture'] as String?;

      final existing = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        try {
          final payload = <String, dynamic>{
            'id': user.id,
            'full_name': metadataName,
            'email': user.email,
          };
          if (avatarUrl != null) {
            payload['avatar_url'] = avatarUrl;
          }
          await _client.from('profiles').insert(payload);
        } catch (_) {}
      } else {
        final existingName = (existing['full_name'] as String?)?.trim();
        if (existingName == null ||
            existingName.isEmpty ||
            existingName == 'Customer') {
          try {
            final updatePayload = <String, dynamic>{
              'full_name': metadataName,
              'updated_at': DateTime.now().toIso8601String(),
            };
            if (avatarUrl != null) {
              updatePayload['avatar_url'] = avatarUrl;
            }
            await _client
                .from('profiles')
                .update(updatePayload)
                .eq('id', user.id);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('syncCustomerSession error: $e');
    }
  }

  /// Get role for current user
  Future<AppUserRole> getUserRole(String userId) async {
    try {
      final rolesRes = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roleList = (rolesRes as List)
          .map((r) => r['role'] as String?)
          .whereType<String>()
          .toList();

      if (roleList.contains('super_admin')) return AppUserRole.superAdmin;
      if (roleList.contains('branch_admin')) return AppUserRole.branchAdmin;
      if (roleList.contains('branch_staff')) return AppUserRole.branchStaff;
      if (roleList.contains('delivery_staff')) return AppUserRole.deliveryStaff;
      return AppUserRole.customer;
    } catch (e) {
      return AppUserRole.customer;
    }
  }

  /// Get staff branch assignment if applicable
  Future<String?> getStaffBranchId(String userId) async {
    try {
      final res = await _client
          .from('branch_staff')
          .select('branch_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      return res?['branch_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if initial administrator bootstrap is available
  Future<bool> isInitialAdminBootstrapAvailable() async {
    try {
      final res = await _client.rpc('is_admin_bootstrap_available');
      return res as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Secure one-time administrator bootstrap
  Future<bool> bootstrapInitialAdmin({
    required String email,
    required String password,
    required String fullName,
    required String bootstrapSecret,
  }) async {
    final res = await _client.rpc(
      'bootstrap_initial_admin',
      params: {
        'p_admin_email': email.trim(),
        'p_admin_password': password,
        'p_admin_name': fullName.trim(),
        'p_bootstrap_secret': bootstrapSecret.trim(),
      },
    );
    return res != null;
  }

  /// Admin method: Create a new staff or delivery partner via secure PostgreSQL RPC
  Future<Map<String, dynamic>> adminCreateStaffOrAgent({
    required String email,
    required String password,
    required String fullName,
    required dynamic role, // accepts AppUserRole or String
    String? branchId,
  }) async {
    final roleString = role is AppUserRole ? role.toDb() : role.toString();
    final res = await _client.rpc(
      'admin_create_staff_or_agent',
      params: {
        'p_email': email.trim(),
        'p_password': password,
        'p_full_name': fullName.trim(),
        'p_role': roleString,
        'p_branch_id': branchId,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  /// Admin method: Toggle active / inactive status of a staff member or agent
  Future<void> adminToggleUserActive({
    required String targetUserId,
    required bool shouldBeActive,
  }) async {
    await _client.rpc(
      'admin_toggle_user_active',
      params: {'p_target_user_id': targetUserId, 'p_is_active': shouldBeActive},
    );
  }

  /// Admin method: Reassign staff to another branch
  Future<void> adminReassignStaffBranch({
    required String staffUserId,
    required String newBranchId,
  }) async {
    await _client.rpc(
      'admin_reassign_staff_branch',
      params: {'p_target_user_id': staffUserId, 'p_new_branch_id': newBranchId},
    );
  }

  /// Admin method: Update staff member or delivery partner details
  Future<void> adminUpdateStaffOrAgent({
    required String targetUserId,
    required String fullName,
    String? email,
    String? phone,
    bool isActive = true,
    String? branchId,
  }) async {
    try {
      await _client.rpc(
        'admin_update_staff_or_agent',
        params: {
          'p_target_user_id': targetUserId,
          'p_full_name': fullName.trim(),
          'p_phone': (phone != null && phone.trim().isNotEmpty)
              ? phone.trim()
              : null,
          'p_is_active': isActive,
          'p_branch_id': branchId,
          'p_email': (email != null && email.trim().isNotEmpty)
              ? email.trim().toLowerCase()
              : null,
        },
      );
    } catch (e) {
      debugPrint('Error updating staff/agent: $e');
      throw Exception(_parseAuthError(e));
    }
  }

  /// Admin method: Safely delete a staff member or delivery partner
  Future<void> adminDeleteStaffOrAgent({required String targetUserId}) async {
    try {
      await _client.rpc(
        'admin_delete_staff_or_agent',
        params: {'p_target_user_id': targetUserId},
      );
    } catch (e) {
      debugPrint('Error deleting staff/agent: $e');
      throw Exception(_parseAuthError(e));
    }
  }

  String _parseAuthError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('active delivery assignment') ||
        msg.contains('Cannot delete delivery partner')) {
      final reg = RegExp(r'Cannot delete delivery partner:[^"]*');
      final match = reg.firstMatch(msg);
      if (match != null) return match.group(0)!;
      return 'Cannot delete delivery partner: They currently have active delivery assignments in progress. Please reassign or complete those orders first.';
    }
    if (msg.contains('Active ongoing order')) {
      return 'Cannot delete user: Active ongoing customer orders exist for this account.';
    }
    if (msg.contains('Cannot delete your own')) {
      return 'You cannot delete your own administrator account.';
    }
    if (msg.contains('Super administrator')) {
      return 'Super administrator accounts cannot be deleted.';
    }
    if (msg.contains('violates foreign key constraint')) {
      return 'Cannot delete account because it is referenced in system records. You can suspend or deactivate the account instead.';
    }
    return msg
        .replaceAll('PostgrestException(', '')
        .replaceAll('message:', '')
        .replaceAll('Exception:', '')
        .replaceAll(RegExp(r', code:.*'), '')
        .trim();
  }

  /// Admin method: Retrieve list of branch staff
  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    try {
      final res = await _client
          .from('branch_staff')
          .select(
            'branch_id, role, is_active, branches(name, area), profiles:user_id(id, full_name, email, phone, avatar_url, is_active)',
          );

      final list = <Map<String, dynamic>>[];
      for (final item in (res as List)) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final branch = item['branches'] as Map<String, dynamic>?;
        if (profile != null) {
          list.add({
            'id': profile['id'],
            'full_name': profile['full_name'],
            'email': profile['email'],
            'phone': profile['phone'],
            'is_active':
                (profile['is_active'] as bool? ?? true) &&
                (item['is_active'] as bool? ?? true),
            'branch_id': item['branch_id'],
            'branch_name': branch?['name'] ?? 'Store Hub',
            'branch_area': branch?['area'] ?? '',
          });
        }
      }
      return list;
    } catch (e) {
      debugPrint('Error getting staff users: $e');
      return [];
    }
  }

  /// Admin method: Retrieve list of delivery partners
  Future<List<Map<String, dynamic>>> getDeliveryAgents() async {
    try {
      final res = await _client
          .from('user_roles')
          .select(
            'user_id, role, profiles:user_id(id, full_name, email, phone, avatar_url, is_active)',
          )
          .eq('role', 'delivery_staff');

      final list = <Map<String, dynamic>>[];
      for (final item in (res as List)) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          list.add({
            'id': profile['id'],
            'full_name': profile['full_name'],
            'email': profile['email'],
            'phone': profile['phone'],
            'is_active': profile['is_active'] as bool? ?? true,
          });
        }
      }
      return list;
    } catch (e) {
      debugPrint('Error getting delivery agents: $e');
      return [];
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
