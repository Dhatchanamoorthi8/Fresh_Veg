import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vegora_models/vegora_models.dart';

import 'branch_repository.dart';

class SupabaseBranchRepository implements BranchRepository {
  final SupabaseClient _client;

  SupabaseBranchRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Branch>> getBranches() async {
    try {
      final res = await _client
          .from('branches')
          .select()
          .eq('is_active', true)
          .order('name');

      return (res as List).map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching branches from Supabase: $e');
      rethrow;
    }
  }

  /// Admin method: Retrieve all branches including inactive ones
  Future<List<Branch>> getAllBranches({bool includeInactive = true}) async {
    try {
      var query = _client.from('branches').select();
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }
      final res = await query.order('created_at', ascending: false);
      return (res as List).map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all branches: $e');
      rethrow;
    }
  }

  @override
  Future<Branch?> getBranchById(String id) async {
    try {
      final res = await _client
          .from('branches')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return Branch.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching branch $id from Supabase: $e');
      return null;
    }
  }

  final List<CustomerAddress> _localAddresses = [];

  @override
  Future<List<CustomerAddress>> getSavedAddresses({String? userId}) async {
    try {
      final uid = userId ?? _client.auth.currentUser?.id;
      if (uid == null) {
        return _localAddresses.isNotEmpty
            ? List.unmodifiable(_localAddresses)
            : MockBranchRepository.sampleAddresses;
      }

      final res = await _client
          .from('customer_addresses')
          .select()
          .eq('user_id', uid)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      final dbAddresses = (res as List)
          .map((json) => CustomerAddress.fromJson(json))
          .toList();

      if (dbAddresses.isEmpty) {
        return _localAddresses.isNotEmpty
            ? List.unmodifiable(_localAddresses)
            : MockBranchRepository.sampleAddresses;
      }

      final all = [...dbAddresses];
      for (final local in _localAddresses) {
        if (!all.any((a) => a.id == local.id)) {
          all.add(local);
        }
      }
      return all;
    } catch (e) {
      debugPrint('Error fetching saved addresses from Supabase: $e');
      return _localAddresses.isNotEmpty
          ? List.unmodifiable(_localAddresses)
          : MockBranchRepository.sampleAddresses;
    }
  }

  @override
  Future<void> saveAddress(CustomerAddress address, {String? userId}) async {
    final uid = userId ?? _client.auth.currentUser?.id;

    // Cache locally for instant resilience
    if (address.isDefault) {
      for (var i = 0; i < _localAddresses.length; i++) {
        _localAddresses[i] = _localAddresses[i].copyWith(isDefault: false);
      }
    }
    final existingIdx = _localAddresses.indexWhere((a) => a.id == address.id);
    if (existingIdx >= 0) {
      _localAddresses[existingIdx] = address;
    } else {
      _localAddresses.insert(0, address);
    }

    if (uid == null) return;

    try {
      if (address.isDefault) {
        await _client
            .from('customer_addresses')
            .update({'is_default': false})
            .eq('user_id', uid);
      }

      await _client.from('customer_addresses').upsert({
        if (address.id.isNotEmpty &&
            !address.id.startsWith('addr_demo') &&
            !address.id.startsWith('addr_local'))
          'id': address.id,
        'user_id': uid,
        'title': address.label,
        'full_address': address.fullAddress,
        'landmark': address.landmark,
        'area': address.area,
        'pincode': address.pinCode,
        'is_default': address.isDefault,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error syncing address to Supabase (locally retained): $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('customer_addresses').delete().eq('id', addressId);
  }

  @override
  Future<Branch> getEligibleBranchForAddress(CustomerAddress address) async {
    final branches = await getBranches();
    if (branches.isEmpty) {
      throw Exception('No active branches available in database.');
    }

    // Match by area or coverage keywords
    final addressArea = address.area.toLowerCase();
    for (final branch in branches) {
      if (branch.deliveryCoverage.toLowerCase().contains(addressArea) ||
          branch.area.toLowerCase().contains(addressArea)) {
        return branch;
      }
    }

    // Fallback to first available active branch
    return branches.first;
  }

  // --- Admin Methods ---

  /// Create a new branch with unique validation
  Future<Branch> createBranch(Branch branch) async {
    try {
      // Verify code uniqueness if provided
      if (branch.code.isNotEmpty) {
        final existing = await _client
            .from('branches')
            .select('id')
            .eq('code', branch.code)
            .maybeSingle();
        if (existing != null) {
          throw Exception(
            'A branch with code "${branch.code}" already exists.',
          );
        }
      }

      final payload = branch.toJson();
      payload['created_at'] = DateTime.now().toIso8601String();
      payload['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('branches')
          .insert(payload)
          .select()
          .single();
      return Branch.fromJson(res);
    } catch (e) {
      debugPrint('Error creating branch in Supabase: $e');
      rethrow;
    }
  }

  /// Update existing branch details
  Future<Branch> updateBranch(Branch branch) async {
    try {
      final payload = branch.toJson();
      payload['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('branches')
          .update(payload)
          .eq('id', branch.id)
          .select()
          .single();
      return Branch.fromJson(res);
    } catch (e) {
      debugPrint('Error updating branch in Supabase: $e');
      rethrow;
    }
  }

  /// Toggle active/inactive status (soft-delete / activation)
  Future<void> toggleBranchActive(String branchId, bool isActive) async {
    try {
      await _client
          .from('branches')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', branchId);
    } catch (e) {
      debugPrint('Error toggling branch active status: $e');
      rethrow;
    }
  }

  /// Toggle operating hours / accepting orders switch
  Future<void> toggleBranchStatus(
    String branchId, {
    required bool isOpen,
    required bool isAcceptingOrders,
  }) async {
    try {
      await _client
          .from('branches')
          .update({
            'is_open': isOpen,
            'is_accepting_orders': isAcceptingOrders,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', branchId);
    } catch (e) {
      debugPrint('Error toggling branch status: $e');
      rethrow;
    }
  }
}
