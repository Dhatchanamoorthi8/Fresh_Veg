import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import 'app_providers.dart';

final branchesListProvider = FutureProvider<List<Branch>>((ref) async {
  final repo = ref.watch(branchRepositoryProvider);
  return repo.getBranches();
});

const defaultBranch = Branch(
  id: 'branch_blr_01',
  name: 'Indiranagar Flagship Store',
  area: 'Indiranagar',
  address: 'Shop 14, 100 Feet Road, HAL 2nd Stage, Indiranagar, Bengaluru',
  phone: '+91 80 4123 9901',
  openingHours: '6:30 AM - 10:00 PM',
  deliveryCoverage: 'Indiranagar, Domlur, HAL, Ulsoor, Old Airport Rd',
  estimatedDeliveryMinutes: 25,
  minOrderAmountPaise: 9900,
  freeDeliveryThresholdPaise: 24900,
  standardDeliveryFeePaise: 2900,
);

final selectedBranchProvider = NotifierProvider<SelectedBranchNotifier, Branch>(
  () {
    return SelectedBranchNotifier();
  },
);

class SelectedBranchNotifier extends Notifier<Branch> {
  @override
  Branch build() {
    final branches = ref.watch(branchesListProvider).value;
    if (branches != null && branches.isNotEmpty) {
      return branches.first;
    }
    return defaultBranch;
  }

  void setBranch(Branch branch) {
    state = branch;
  }
}

/// For Branch Staff role: specifies which branch the staff member is managing
final staffSelectedBranchProvider =
    NotifierProvider<StaffSelectedBranchNotifier, Branch>(() {
      return StaffSelectedBranchNotifier();
    });

class StaffSelectedBranchNotifier extends Notifier<Branch> {
  @override
  Branch build() {
    final branches = ref.watch(branchesListProvider).value;
    if (branches != null && branches.isNotEmpty) {
      return branches.first;
    }
    return defaultBranch;
  }

  void setBranch(Branch branch) {
    state = branch;
  }
}
