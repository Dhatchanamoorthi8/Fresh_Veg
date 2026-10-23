import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/branch.dart';
import '../../shared/models/customer_address.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/repositories/branch_repository.dart';
import '../../shared/widgets/branch_switch_dialog.dart';
import '../../shared/widgets/vegora_toast.dart';
import '../../core/services/location_service.dart';
import 'location_picker_map_screen.dart';

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
      backgroundColor: AppColors.background,
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
    dynamic cart,
  ) {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final currentBranch = ref.watch(selectedBranchProvider);

    return addressesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load saved addresses',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(customerAddressesProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 48,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Delivery Addresses Saved',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your address so Vegora can deliver freshly harvested produce directly to your doorstep in 25-35 mins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showAddAddressSheet(context),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Add Delivery Address'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: OutlinedButton.icon(
                  onPressed: () => _showAddAddressSheet(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text(
                    'Add New Delivery Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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

  Widget _buildLabelChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAddressSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final currentBranch = ref.read(selectedBranchProvider);
    final branches =
        ref.read(branchesListProvider).value ??
        MockBranchRepository.sampleBranches;

    String selectedLabel = 'Home';
    Branch? selectedDbBranch;
    double? selectedLat;
    double? selectedLng;

    final addressController = TextEditingController();
    final areaController = TextEditingController();
    final landmarkController = TextEditingController();
    final pinCodeController = TextEditingController();
    bool isDefault = false;
    bool isLocatingGps = false;
    bool showStorePicker = false;
    String? mapVerifiedAddressSummary;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void applyStoreBranch(Branch branch) {
              setSheetState(() {
                selectedDbBranch = branch;
                addressController.text = branch.address;
                areaController.text = branch.area;
                if (branch.pincode.isNotEmpty) {
                  pinCodeController.text = branch.pincode;
                }
                selectedLat = branch.latitude;
                selectedLng = branch.longitude;
                mapVerifiedAddressSummary = '${branch.name} (${branch.area})';
              });
            }

            Future<void> openMapLocationPicker({bool fetchGpsFirst = false}) async {
              double targetLat = selectedLat ?? currentBranch.latitude ?? LocationService.defaultLat;
              double targetLng = selectedLng ?? currentBranch.longitude ?? LocationService.defaultLng;

              if (fetchGpsFirst) {
                setSheetState(() => isLocatingGps = true);
                final pos = await LocationService.instance.getCurrentPosition();
                setSheetState(() => isLocatingGps = false);
                if (pos != null) {
                  targetLat = pos.latitude;
                  targetLng = pos.longitude;
                }
              }

              if (!sheetContext.mounted) return;

              final SelectedLocationResult? result =
                  await Navigator.of(sheetContext).push<SelectedLocationResult>(
                MaterialPageRoute(
                  builder: (_) => LocationPickerMapScreen(
                    initialLatitude: targetLat,
                    initialLongitude: targetLng,
                    initialTitle: areaController.text.isNotEmpty
                        ? areaController.text
                        : currentBranch.name,
                  ),
                ),
              );

              if (result != null) {
                setSheetState(() {
                  selectedLat = result.latitude;
                  selectedLng = result.longitude;
                  selectedDbBranch = null; // Verified directly via exact doorstep map pin
                  if (result.flatBuilding.isNotEmpty &&
                      addressController.text.trim().isEmpty) {
                    addressController.text = result.flatBuilding;
                  }
                  if (result.areaLocality.isNotEmpty) {
                    areaController.text = result.areaLocality;
                  }
                  if (result.pincode.isNotEmpty) {
                    pinCodeController.text = result.pincode;
                  }
                  mapVerifiedAddressSummary = result.areaLocality.isNotEmpty
                      ? '${result.areaLocality}, ${result.city}'
                      : '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Delivery Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Address Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLabelChip(
                            label: 'Home',
                            icon: Icons.home_rounded,
                            isSelected: selectedLabel == 'Home',
                            onTap: () =>
                                setSheetState(() => selectedLabel = 'Home'),
                          ),
                          const SizedBox(width: 8),
                          _buildLabelChip(
                            label: 'Office',
                            icon: Icons.work_rounded,
                            isSelected: selectedLabel == 'Office',
                            onTap: () =>
                                setSheetState(() => selectedLabel = 'Office'),
                          ),
                          const SizedBox(width: 8),
                          _buildLabelChip(
                            label: 'Other',
                            icon: Icons.location_on_rounded,
                            isSelected: selectedLabel == 'Other',
                            onTap: () =>
                                setSheetState(() => selectedLabel = 'Other'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Delivery Location: Current GPS & Map Verification Hero Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryContainer.withValues(alpha: 0.45),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedLat != null
                                ? AppColors.primary
                                : AppColors.primaryLight.withValues(alpha: 0.5),
                            width: selectedLat != null ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isLocatingGps
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Delivery Location',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (selectedLat != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'VERIFIED ON MAP',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        selectedLat != null
                                            ? (mapVerifiedAddressSummary != null
                                                ? '📍 $mapVerifiedAddressSummary'
                                                : 'Lat: ${selectedLat!.toStringAsFixed(5)}, Lng: ${selectedLng!.toStringAsFixed(5)}')
                                            : 'Click below to detect your current location and verify on the map.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: selectedLat != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selectedLat != null
                                              ? AppColors.primaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (selectedLat != null && selectedLng != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
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
                                        'GPS: ${selectedLat!.toStringAsFixed(6)}° N, ${selectedLng!.toStringAsFixed(6)}° E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          selectedDbBranch = null;
                                          selectedLat = null;
                                          selectedLng = null;
                                          mapVerifiedAddressSummary = null;
                                        });
                                      },
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.statusCancelled,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Dual Action Buttons: GPS Detect & Map Verification
                            Row(
                              children: [
                                // 1. Main Get Current Location Button
                                Expanded(
                                  flex: 6,
                                  child: ElevatedButton.icon(
                                    onPressed: isLocatingGps
                                        ? null
                                        : () => openMapLocationPicker(fetchGpsFirst: true),
                                    icon: isLocatingGps
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.near_me_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      selectedLat != null
                                          ? 'Re-Detect GPS'
                                          : 'Get Current Location',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 2. Interactive Map View Button
                                Expanded(
                                  flex: 5,
                                  child: OutlinedButton.icon(
                                    onPressed: isLocatingGps
                                        ? null
                                        : () => openMapLocationPicker(fetchGpsFirst: false),
                                    icon: const Icon(
                                      Icons.map_outlined,
                                      size: 16,
                                      color: AppColors.primaryDark,
                                    ),
                                    label: Text(
                                      selectedLat != null ? 'Adjust on Map' : 'View on Map',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.2,
                                      ),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Collapsible Option: Select Store Branch Coordinates
                            InkWell(
                              onTap: () => setSheetState(
                                () => showStorePicker = !showStorePicker,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      showStorePicker
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_right_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Or select from store branch network',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (showStorePicker) ...[
                              const SizedBox(height: 8),
                              // Option A: 1-tap button to use CURRENT fulfillment store
                              InkWell(
                                onTap: () => applyStoreBranch(currentBranch),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selectedDbBranch?.id == currentBranch.id
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: selectedDbBranch?.id == currentBranch.id ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.store_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Store: ${currentBranch.name}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (currentBranch.latitude != null &&
                                                currentBranch.longitude != null)
                                              Text(
                                                'GPS: ${currentBranch.latitude!.toStringAsFixed(4)}° N, ${currentBranch.longitude!.toStringAsFixed(4)}° E',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.touch_app_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Option B: Dropdown to pick ANY branch from the database
                              DropdownButtonFormField<Branch>(
                                initialValue: selectedDbBranch,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Select Store Network DB',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(
                                    Icons.hub_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                hint: const Text(
                                  'Choose store branch...',
                                  style: TextStyle(fontSize: 12),
                                ),
                                items: branches.map((b) {
                                  return DropdownMenuItem<Branch>(
                                    value: b,
                                    child: Text(
                                      '${b.name} (${b.area})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (b) {
                                  if (b != null) {
                                    applyStoreBranch(b);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Flat / House No. / Building / Street',
                          hintText: 'e.g., Flat 402, Green Meadows, 12th Cross',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.location_city_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter your street address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: areaController,
                        decoration: InputDecoration(
                          labelText: 'Area / Locality',
                          hintText:
                              'e.g., Indiranagar, Whitefield, Koramangala',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.map_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter locality/area'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: landmarkController,
                              decoration: InputDecoration(
                                labelText: 'Landmark (Optional)',
                                hintText: 'e.g., Near Metro',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: pinCodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'PIN Code',
                                hintText: '560038',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter PIN';
                                }
                                if (v.trim().length != 6) {
                                  return '6 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: isDefault,
                        onChanged: (val) =>
                            setSheetState(() => isDefault = val ?? false),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Make this my default delivery address',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final newAddr = CustomerAddress(
                              id: 'addr_local_${DateTime.now().millisecondsSinceEpoch}',
                              label: selectedLabel,
                              fullAddress: addressController.text.trim(),
                              area: areaController.text.trim(),
                              landmark: landmarkController.text.trim(),
                              pinCode: pinCodeController.text.trim(),
                              eligibleBranchId:
                                  selectedDbBranch?.id ?? 'branch_blr_01',
                              isDefault: isDefault,
                              latitude: selectedLat,
                              longitude: selectedLng,
                            );

                            final eligibleBranch =
                                selectedDbBranch ??
                                await ref
                                    .read(branchRepositoryProvider)
                                    .getEligibleBranchForAddress(newAddr);

                            final finalAddr = newAddr.copyWith(
                              eligibleBranchId: eligibleBranch.id,
                              latitude: selectedLat ?? eligibleBranch.latitude,
                              longitude:
                                  selectedLng ?? eligibleBranch.longitude,
                            );

                            await ref
                                .read(branchRepositoryProvider)
                                .saveAddress(finalAddr);

                            ref.invalidate(customerAddressesProvider);
                            ref
                                .read(selectedAddressProvider.notifier)
                                .setAddress(finalAddr);
                            ref
                                .read(selectedBranchProvider.notifier)
                                .setBranch(eligibleBranch);

                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            VegoraToast.showSuccess(
                              context,
                              'Delivery address added (${finalAddr.area})! Fulfilling from ${eligibleBranch.name}',
                              title: 'Address Saved',
                              icon: Icons.location_on_rounded,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save & Deliver to this Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    addressController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    pinCodeController.dispose();
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
