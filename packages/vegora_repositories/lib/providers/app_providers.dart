import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/branch_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/supabase_auth_repository.dart';
import '../repositories/supabase_branch_repository.dart';
import '../repositories/supabase_catalog_repository.dart';
import '../repositories/supabase_order_repository.dart';

final authRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return SupabaseBranchRepository();
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SupabaseCatalogRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository();
});
