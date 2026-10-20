import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';
import 'package:vegora_ui/vegora_ui.dart';

class BranchSelectionScreen extends ConsumerStatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  ConsumerState<BranchSelectionScreen> createState() =>
      _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends ConsumerState<BranchSelectionScreen> {
  int _selectedTabIndex = 0; // 0: Store Branches, 1: Saved Addresses

  @override
  Widget build(BuildContext context) {
    final currentBranch = ref.watch(selectedBranchProvider);
    final currentAddress = ref.watch(selectedAddressProvider);
    final branchesAsync = ref.watch(branchesListProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Branch & Address')),
      body: Column(
        children: [
          // Current Selection Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT FULFILLMENT STORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentBranch.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Est. Delivery: ~${currentBranch.estimatedDeliveryMinutes} mins • Free above ${CurrencyFormatter.formatPaise(currentBranch.freeDeliveryThresholdPaise)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (currentBranch.latitude != null &&
                          currentBranch.longitude != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              size: 11,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Store DB GPS: ${currentBranch.latitude!.toStringAsFixed(4)}° N, ${currentBranch.longitude!.toStringAsFixed(4)}° E',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    title: 'Physical Branches (5+)',
                    isSelected: _selectedTabIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    title: 'Delivery Addresses',
                    isSelected: _selectedTabIndex == 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content List
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildBranchesList(
                    context,
                    branchesAsync,
                    currentBranch,
                    cart,
                  )
                : _buildAddressesList(context, currentAddress, cart),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBranchesList(
    BuildContext context,
    AsyncValue<List<Branch>> branchesAsync,
    Branch currentBranch,
    cart,
  ) {
    return branchesAsync.when(
      data: (branches) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: branches.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final branch = branches[index];
            final isSelected = branch.id == currentBranch.id;

            return InkWell(
              onTap: () => _selectBranch(context, branch, currentBranch, cart),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    branch.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: branch.isOpen
                                          ? AppColors.primaryContainer
                                          : AppColors.statusCancelled
                                                .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      branch.isOpen ? 'OPEN' : 'CLOSED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: branch.isOpen
                                            ? AppColors.onPrimaryContainer
                                            : AppColors.statusCancelled,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Branch ID: ${branch.id}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (branch.latitude != null &&
                        branch.longitude != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'GPS: ${branch.latitude!.toStringAsFixed(4)}° N, ${branch.longitude!.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          branch.openingHours,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.delivery_dining_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${branch.estimatedDeliveryMinutes} min delivery',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text(
                      'Coverage: ${branch.deliveryCoverage}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading branches: $err')),
    );
  }

  Widget _buildAddressesList(
    BuildContext context,
    CustomerAddress currentAddress,
    cart,
  ) {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final currentBranch = ref.watch(selectedBranchProvider);

    return addressesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 12),
              const Text('Could not load your saved addresses.'),
              TextButton(
                onPressed: () => ref.invalidate(customerAddressesProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No delivery addresses yet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add an address to see nearby delivery options.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _addAddress(context, list),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add delivery address'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return OutlinedButton.icon(
                onPressed: () => _addAddress(context, list),
                icon: const Icon(Icons.add),
                label: const Text('Add another address'),
              );
            }
            final addr = list[index];
            final isSelected = addr.id == currentAddress.id;

            return InkWell(
              onTap: () async {
                final eligibleBranch = await ref
                    .read(branchRepositoryProvider)
                    .getEligibleBranchForAddress(addr);

                if (!context.mounted) return;

                if (eligibleBranch.id != currentBranch.id && cart.isNotEmpty) {
                  BranchSwitchDialog.show(
                    context: context,
                    currentBranch: currentBranch,
                    newBranch: eligibleBranch,
                    onConfirm: () {
                      ref.read(cartProvider.notifier).clearCart();
                      ref
                          .read(selectedBranchProvider.notifier)
                          .setBranch(eligibleBranch);
                      ref
                          .read(selectedAddressProvider.notifier)
                          .setAddress(addr);
                      Navigator.pop(context);
                      VegoraToast.showAddressSelected(
                        context,
                        addressLabel: addr.label,
                        area: addr.area,
                        branchName: eligibleBranch.name,
                      );
                    },
                  );
                } else {
                  ref
                      .read(selectedBranchProvider.notifier)
                      .setBranch(eligibleBranch);
                  ref.read(selectedAddressProvider.notifier).setAddress(addr);
                  Navigator.pop(context);
                  VegoraToast.showAddressSelected(
                    context,
                    addressLabel: addr.label,
                    area: addr.area,
                    branchName: eligibleBranch.name,
                  );
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        addr.label == 'Home'
                            ? Icons.home_rounded
                            : addr.label == 'Office'
                            ? Icons.work_rounded
                            : Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addr.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.fullAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Area: ${addr.area} • PIN: ${addr.pinCode}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (addr.latitude != null &&
                              addr.longitude != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 11,
                                    color: AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lat: ${addr.latitude!.toStringAsFixed(4)}, Long: ${addr.longitude!.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderDark,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addAddress(
    BuildContext context,
    List<CustomerAddress> existingAddresses,
  ) async {
    final address = await _showAddAddressDialog(
      context,
      makeDefault: existingAddresses.isEmpty,
    );
    if (address == null || !context.mounted) return;

    try {
      final eligibleBranch = await ref
          .read(branchRepositoryProvider)
          .getEligibleBranchForAddress(address);

      final finalAddress = address.copyWith(
        eligibleBranchId: eligibleBranch.id,
      );

      await ref.read(branchRepositoryProvider).saveAddress(finalAddress);
      ref.invalidate(customerAddressesProvider);
      ref.read(selectedAddressProvider.notifier).setAddress(finalAddress);
      ref.read(selectedBranchProvider.notifier).setBranch(eligibleBranch);

      if (!context.mounted) return;
      VegoraToast.showSuccess(
        context,
        'Delivery address saved! Fulfilling from ${eligibleBranch.name}',
        title: 'Address Saved',
        icon: Icons.location_on_rounded,
      );
    } catch (error) {
      if (!context.mounted) return;
      VegoraToast.showError(
        context,
        'Could not save address: $error',
        title: 'Error Saving Address',
      );
    }
  }

  Future<CustomerAddress?> _showAddAddressDialog(
    BuildContext context, {
    required bool makeDefault,
  }) async {
    final formKey = GlobalKey<FormState>();
    final currentBranch = ref.read(selectedBranchProvider);
    final branches =
        ref.read(branchesListProvider).value ??
        MockBranchRepository.sampleBranches;

    final labelController = TextEditingController(text: 'Home');
    final addressController = TextEditingController();
    final areaController = TextEditingController();
    final landmarkController = TextEditingController();
    final pinCodeController = TextEditingController();

    Branch? selectedDbBranch;
    double? selectedLat;
    double? selectedLng;

    final result = await showDialog<CustomerAddress>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void applyStoreBranch(Branch branch) {
            setDialogState(() {
              selectedDbBranch = branch;
              addressController.text = branch.address;
              areaController.text = branch.area;
              if (branch.pincode.isNotEmpty) {
                pinCodeController.text = branch.pincode;
              }
              selectedLat = branch.latitude;
              selectedLng = branch.longitude;
            });
          }

          return AlertDialog(
            title: const Text('Add delivery address'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store DB Location & GPS Coordinates Selector
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store_mall_directory_rounded,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Pick Store Location (DB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const Spacer(),
                              if (selectedLat != null && selectedLng != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'GPS LOCKED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Quick 1-tap button to use CURRENT fulfillment store
                          InkWell(
                            onTap: () => applyStoreBranch(currentBranch),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      selectedDbBranch?.id == currentBranch.id
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width:
                                      selectedDbBranch?.id == currentBranch.id
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Use Current Store: ${currentBranch.name}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dropdown to pick ANY branch from the database
                          DropdownButtonFormField<Branch>(
                            initialValue: selectedDbBranch,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Or Pick Any Store from DB',
                              labelStyle: const TextStyle(fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            hint: const Text(
                              'Choose store...',
                              style: TextStyle(fontSize: 11),
                            ),
                            items: branches.map((b) {
                              return DropdownMenuItem<Branch>(
                                value: b,
                                child: Text(
                                  '${b.name} (${b.latitude?.toStringAsFixed(4)}, ${b.longitude?.toStringAsFixed(4)})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }).toList(),
                            onChanged: (b) {
                              if (b != null) {
                                applyStoreBranch(b);
                              }
                            },
                          ),

                          // Active Coordinates Info Banner
                          if (selectedLat != null && selectedLng != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Lat: ${selectedLat!.toStringAsFixed(6)} | Long: ${selectedLng!.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    _addressField(labelController, 'Label (Home, Office)'),
                    _addressField(
                      addressController,
                      'Full address',
                      maxLines: 2,
                    ),
                    _addressField(areaController, 'Area'),
                    _addressField(
                      landmarkController,
                      'Landmark (optional)',
                      required: false,
                    ),
                    _addressField(
                      pinCodeController,
                      'PIN code',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final branch = selectedDbBranch ?? currentBranch;
                  Navigator.pop(
                    dialogContext,
                    CustomerAddress(
                      id: 'addr_demo_${DateTime.now().microsecondsSinceEpoch}',
                      label: labelController.text.trim(),
                      fullAddress: addressController.text.trim(),
                      area: areaController.text.trim(),
                      landmark: landmarkController.text.trim(),
                      pinCode: pinCodeController.text.trim(),
                      eligibleBranchId: branch.id,
                      isDefault: makeDefault,
                      latitude: selectedLat ?? branch.latitude,
                      longitude: selectedLng ?? branch.longitude,
                    ),
                  );
                },
                child: const Text('Save address'),
              ),
            ],
          );
        },
      ),
    );

    labelController.dispose();
    addressController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    pinCodeController.dispose();
    return result;
  }

  Widget _addressField(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Please enter ${label.toLowerCase()}'
                  : null
            : null,
      ),
    );
  }

  void _selectBranch(
    BuildContext context,
    Branch branch,
    Branch currentBranch,
    cart,
  ) {
    if (branch.id == currentBranch.id) {
      Navigator.pop(context);
      return;
    }

    // Check if cart has items from previous branch
    if (cart.isNotEmpty) {
      BranchSwitchDialog.show(
        context: context,
        currentBranch: currentBranch,
        newBranch: branch,
        onConfirm: () {
          ref.read(cartProvider.notifier).clearCart();
          ref.read(selectedBranchProvider.notifier).setBranch(branch);
          Navigator.pop(context);
          VegoraToast.showWarning(
            context,
            'Switched store to ${branch.name}. Cart cleared.',
            title: 'Store Switched',
            icon: Icons.storefront_rounded,
          );
        },
      );
    } else {
      ref.read(selectedBranchProvider.notifier).setBranch(branch);
      Navigator.pop(context);
      VegoraToast.showSuccess(
        context,
        'Store branch updated to ${branch.name}',
        title: 'Store Selected',
        icon: Icons.storefront_rounded,
      );
    }
  }
}
