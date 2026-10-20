import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_table_container.dart';

class AdminBranchesScreen extends ConsumerStatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  ConsumerState<AdminBranchesScreen> createState() =>
      _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends ConsumerState<AdminBranchesScreen> {
  bool _isLoading = true;
  List<Branch> _branches = [];
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(branchRepositoryProvider);
      if (repo is SupabaseBranchRepository) {
        final list = await repo.getAllBranches(includeInactive: true);
        if (mounted) setState(() => _branches = list);
      } else {
        final list = await repo.getBranches();
        if (mounted) setState(() => _branches = list);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load branches: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Branch> get _filteredBranches {
    return _branches.where((b) {
      if (_statusFilter == 'ACTIVE' && !b.isActive) return false;
      if (_statusFilter == 'INACTIVE' && b.isActive) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = b.name.toLowerCase().contains(q);
        final matchCode = b.code.toLowerCase().contains(q);
        final matchArea = b.area.toLowerCase().contains(q);
        final matchCity = b.city.toLowerCase().contains(q);
        final matchManager = (b.managerName ?? '').toLowerCase().contains(q);
        return matchName || matchCode || matchArea || matchCity || matchManager;
      }
      return true;
    }).toList();
  }

  void _showAddEditBranchModal([Branch? existingBranch]) {
    final isEditing = existingBranch != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: existingBranch?.name ?? '');
    final codeCtrl = TextEditingController(text: existingBranch?.code ?? '');
    final areaCtrl = TextEditingController(text: existingBranch?.area ?? '');
    final addressCtrl = TextEditingController(
      text: existingBranch?.address ?? '',
    );
    final cityCtrl = TextEditingController(
      text: existingBranch?.city ?? 'Bengaluru',
    );
    final stateCtrl = TextEditingController(
      text: existingBranch?.state ?? 'Karnataka',
    );
    final pincodeCtrl = TextEditingController(
      text: existingBranch?.pincode ?? '',
    );
    final phoneCtrl = TextEditingController(text: existingBranch?.phone ?? '');
    final managerCtrl = TextEditingController(
      text: existingBranch?.managerName ?? '',
    );
    final emailCtrl = TextEditingController(
      text: existingBranch?.contactEmail ?? '',
    );
    final hoursCtrl = TextEditingController(
      text: existingBranch?.openingHours ?? '6:30 AM - 10:00 PM',
    );
    final coverageCtrl = TextEditingController(
      text: existingBranch?.deliveryCoverage ?? '',
    );
    final minOrderCtrl = TextEditingController(
      text: ((existingBranch?.minOrderAmountPaise ?? 9900) / 100)
          .toStringAsFixed(0),
    );
    final freeDeliveryCtrl = TextEditingController(
      text: ((existingBranch?.freeDeliveryThresholdPaise ?? 24900) / 100)
          .toStringAsFixed(0),
    );
    final deliveryFeeCtrl = TextEditingController(
      text: ((existingBranch?.standardDeliveryFeePaise ?? 2900) / 100)
          .toStringAsFixed(0),
    );

    bool isOpen = existingBranch?.isOpen ?? true;
    bool isAccepting = existingBranch?.isAcceptingOrders ?? true;
    bool isActive = existingBranch?.isActive ?? true;
    bool isSaving = false;
    String? modalError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditing
                      ? Icons.edit_location_alt_rounded
                      : Icons.add_business_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Branch' : 'Add New Branch',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (modalError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Section 1: Identifiers
                    const Text(
                      'Branch Identification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Branch Name *',
                              hintText: 'e.g. Indiranagar Flagship Store',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Branch name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Branch Code *',
                              hintText: 'e.g. BR-IND-01',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Code required';
                              }
                              if (v.trim().length < 3) {
                                return 'Min 3 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Location
                    const Text(
                      'Location & Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Area / Neighborhood *',
                        hintText: 'e.g. HAL 2nd Stage, Indiranagar',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Area is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Full Address *',
                        hintText: 'e.g. Shop 14, 100 Feet Road, Indiranagar',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'City required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'State required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: pincodeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'PIN Code *',
                              hintText: '560038',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'PIN required';
                              }
                              if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                                return 'Enter 6-digit PIN';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Contact & Management
                    const Text(
                      'Contact & Management',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: managerCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Manager Name',
                              hintText: 'e.g. Ramesh Kumar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone *',
                              hintText: '+91 80 4123 9901',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Phone required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        hintText: 'manager.indiranagar@vegora.in',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Section 4: Operations & Delivery Thresholds
                    const Text(
                      'Operations & Delivery Parameters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: hoursCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Opening Hours',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: coverageCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Coverage (Areas)',
                              hintText: 'Indiranagar, HAL, Domlur',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Order (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: freeDeliveryCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Free Delivery At (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: deliveryFeeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Standard Fee (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status Switches
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Active Store Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Store is available in app service directory',
                            ),
                            value: isActive,
                            activeTrackColor: AppColors.primaryLight,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) =>
                                setDialogState(() => isActive = v),
                          ),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Store Open',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Branch is currently open for operations',
                            ),
                            value: isOpen,
                            activeTrackColor: AppColors.primaryLight,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setDialogState(() => isOpen = v),
                          ),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Accepting Customer Orders',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Allow customers to place new orders from this branch',
                            ),
                            value: isAccepting,
                            activeTrackColor: AppColors.primaryLight,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) =>
                                setDialogState(() => isAccepting = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isSaving = true;
                        modalError = null;
                      });

                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final repo = ref.read(branchRepositoryProvider);
                        if (repo is! SupabaseBranchRepository) {
                          throw Exception(
                            'Supabase branch repository is not configured.',
                          );
                        }

                        final branchId = isEditing
                            ? existingBranch.id
                            : 'branch_${codeCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

                        final minPaise =
                            (double.tryParse(minOrderCtrl.text.trim()) ??
                                99.0) *
                            100;
                        final freePaise =
                            (double.tryParse(freeDeliveryCtrl.text.trim()) ??
                                249.0) *
                            100;
                        final feePaise =
                            (double.tryParse(deliveryFeeCtrl.text.trim()) ??
                                29.0) *
                            100;

                        final branchPayload = Branch(
                          id: branchId,
                          name: nameCtrl.text.trim(),
                          code: codeCtrl.text.trim().toUpperCase(),
                          area: areaCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          state: stateCtrl.text.trim(),
                          pincode: pincodeCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          managerName: managerCtrl.text.trim().isEmpty
                              ? null
                              : managerCtrl.text.trim(),
                          contactEmail: emailCtrl.text.trim().isEmpty
                              ? null
                              : emailCtrl.text.trim(),
                          openingHours: hoursCtrl.text.trim().isEmpty
                              ? '6:30 AM - 10:00 PM'
                              : hoursCtrl.text.trim(),
                          deliveryCoverage: coverageCtrl.text.trim().isEmpty
                              ? areaCtrl.text.trim()
                              : coverageCtrl.text.trim(),
                          minOrderAmountPaise: minPaise.round(),
                          freeDeliveryThresholdPaise: freePaise.round(),
                          standardDeliveryFeePaise: feePaise.round(),
                          isOpen: isOpen,
                          isAcceptingOrders: isAccepting,
                          isActive: isActive,
                        );

                        if (isEditing) {
                          await repo.updateBranch(branchPayload);
                        } else {
                          await repo.createBranch(branchPayload);
                        }

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Branch "${branchPayload.name}" updated successfully!'
                                    : 'Branch "${branchPayload.name}" created successfully!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadBranches();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          modalError = e
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim();
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditing ? 'Save Changes' : 'Save Branch',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBranchActive(Branch branch) async {
    final nextState = !branch.isActive;
    try {
      final repo = ref.read(branchRepositoryProvider);
      if (repo is SupabaseBranchRepository) {
        await repo.toggleBranchActive(branch.id, nextState);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextState
                  ? 'Branch "${branch.name}" activated.'
                  : 'Branch "${branch.name}" deactivated (historical data preserved).',
            ),
            backgroundColor: nextState
                ? AppColors.primary
                : AppColors.neutral700,
          ),
        );
        _loadBranches();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update branch status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final branches = _filteredBranches;

    return AdminScaffold(
      currentSection: AdminMenuSection.branches,
      title: 'Manage Branches',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _loadBranches,
        ),
      ],
      body: Column(
        children: [
          // Header Action Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search branches by name, code, area, city...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Branches'),
                        ),
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active Only'),
                        ),
                        DropdownMenuItem(
                          value: 'INACTIVE',
                          child: Text('Inactive Only'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _statusFilter = v;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6B3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Add Branch',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: () => _showAddEditBranchModal(),
                ),
              ],
            ),
          ),

          // Content List / Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : branches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 64,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No branches match your filters.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddEditBranchModal(),
                          child: const Text('Add New Branch'),
                        ),
                      ],
                    ),
                  )
                : isDesktop
                ? _buildDesktopTable(branches)
                : _buildMobileCards(branches),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Branch> branches) {
    final paginatedBranches = branches
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminTableContainer(
        currentPage: _currentPage,
        totalItems: branches.length,
        rowsPerPage: _rowsPerPage,
        onPageChanged: (page) => setState(() => _currentPage = page),
        onRowsPerPageChanged: (rows) => setState(() {
          _rowsPerPage = rows;
          _currentPage = 1;
        }),
        itemName: 'branches',
        columns: const [
          AdminTableColumn(title: 'Branch Name & Code', flex: 3),
          AdminTableColumn(title: 'Manager & Contact', flex: 2),
          AdminTableColumn(title: 'Location & PIN', flex: 2),
          AdminTableColumn(title: 'Store Status', flex: 1),
          AdminTableColumn(title: 'Accepting Orders', flex: 1),
          AdminTableColumn(
            title: 'Actions',
            flex: 1,
            alignment: Alignment.centerRight,
          ),
        ],
        rows: paginatedBranches.map((branch) {
          return AdminTableRow(
            cells: [
              // 0: Branch Name & Code
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      branch.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // 1: Manager & Contact
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.managerName ?? 'Manager Unassigned',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: branch.managerName != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    branch.phone,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (branch.contactEmail != null)
                    Text(
                      branch.contactEmail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),

              // 2: Location & PIN
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${branch.area}, ${branch.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    '${branch.state} • ${branch.pincode}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // 3: Store Status
              AdminStatusBadge(
                label: branch.isActive
                    ? (branch.isOpen ? 'Active (Open)' : 'Active (Closed)')
                    : 'Inactive',
                isActive: branch.isActive,
              ),

              // 4: Accepting Orders
              Transform.scale(
                scale: 0.85,
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: branch.isAcceptingOrders,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFFBBF7D0),
                  onChanged: (val) async {
                    final repo = ref.read(branchRepositoryProvider);
                    if (repo is SupabaseBranchRepository) {
                      await repo.toggleBranchStatus(
                        branch.id,
                        isOpen: branch.isOpen,
                        isAcceptingOrders: val,
                      );
                      _loadBranches();
                    }
                  },
                ),
              ),

              // 5: Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: Color(0xFF475569),
                    ),
                    tooltip: 'Edit Branch',
                    onPressed: () => _showAddEditBranchModal(branch),
                  ),
                  IconButton(
                    icon: Icon(
                      branch.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 26,
                      color: branch.isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                    ),
                    tooltip: branch.isActive
                        ? 'Deactivate Branch'
                        : 'Activate Branch',
                    onPressed: () => _toggleBranchActive(branch),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCards(List<Branch> branches) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: branches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = branches[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Code: ${b.code} • Area: ${b.area}',
                            style: TextStyle(
                              color: AppColors.neutral600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _showAddEditBranchModal(b),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Address: ${b.address}, ${b.city}, ${b.state} - ${b.pincode}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${b.phone} | Manager: ${b.managerName ?? "N/A"}',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral700),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Accepting Orders: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral700,
                          ),
                        ),
                        Switch(
                          value: b.isAcceptingOrders,
                          activeTrackColor: AppColors.primaryLight,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) async {
                            final repo = ref.read(branchRepositoryProvider);
                            if (repo is SupabaseBranchRepository) {
                              await repo.toggleBranchStatus(
                                b.id,
                                isOpen: b.isOpen,
                                isAcceptingOrders: val,
                              );
                              _loadBranches();
                            }
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: b.isActive
                            ? AppColors.neutral200
                            : AppColors.primary,
                        foregroundColor: b.isActive
                            ? AppColors.neutral800
                            : Colors.white,
                      ),
                      onPressed: () => _toggleBranchActive(b),
                      child: Text(b.isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
