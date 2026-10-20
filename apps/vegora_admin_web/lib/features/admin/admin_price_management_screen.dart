import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

class AdminPriceManagementScreen extends ConsumerStatefulWidget {
  const AdminPriceManagementScreen({super.key});

  @override
  ConsumerState<AdminPriceManagementScreen> createState() =>
      _AdminPriceManagementScreenState();
}

class _AdminPriceManagementScreenState
    extends ConsumerState<AdminPriceManagementScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Branch> _branches = [];
  String _searchQuery = '';
  String? _selectedBranchId; // null = all branches comparison

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);
    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      final prods = await (catalogRepo is SupabaseCatalogRepository
          ? catalogRepo.getAdminProducts()
          : catalogRepo.getProducts());
      final brs = await (branchRepo is SupabaseBranchRepository
          ? branchRepo.getAllBranches(includeInactive: false)
          : branchRepo.getBranches());

      if (mounted) {
        setState(() {
          _products = prods;
          _branches = brs;
          if (_selectedBranchId == null && brs.isNotEmpty) {
            _selectedBranchId = brs.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prices: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
    }).toList();
  }

  void _showPriceUpdateModal(Product product, Branch branch) {
    final currentPaise = product.getPricePaiseForBranch(branch.id);
    final priceCtrl = TextEditingController(
      text: (currentPaise / 100).toStringAsFixed(0),
    );
    double proposedPrice = currentPaise / 100.0;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final diff = proposedPrice - (currentPaise / 100.0);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Update Price: ${product.name}'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Branch: ${branch.name} (${branch.code})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unit: ${product.unit} • Catalog Base Price: ${CurrencyFormatter.formatPaise(product.basePricePaise)}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatPaise(currentPaise),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.neutral400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proposed New Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${proposedPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: diff > 0
                                    ? Colors.green.shade800
                                    : diff < 0
                                    ? Colors.orange.shade800
                                    : AppColors.neutral800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (diff != 0)
                    Text(
                      diff > 0
                          ? '+₹${diff.toStringAsFixed(0)} increase (+${((diff / (currentPaise / 100)) * 100).toStringAsFixed(1)}%)'
                          : '-₹${(-diff).toStringAsFixed(0)} discount (${((diff / (currentPaise / 100)) * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: diff > 0
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Selling Price (₹) *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.trim());
                      if (parsed != null && parsed >= 0) {
                        setDialogState(() => proposedPrice = parsed);
                      }
                    },
                  ),
                ],
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
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPricePaise = (proposedPrice * 100).round();
                        setDialogState(() => isSaving = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final repo = ref.read(catalogRepositoryProvider);
                          if (repo is! SupabaseCatalogRepository) return;

                          final inv = product.branchInventory[branch.id];
                          await repo.updateBranchInventoryPricingAndStock(
                            branchId: branch.id,
                            productId: product.id,
                            pricePaise: newPricePaise,
                            stockQuantity: inv?.stockQuantity ?? 15,
                            lowStockThreshold: inv?.lowStockThreshold ?? 5,
                            isAvailable: inv?.isAvailable ?? true,
                          );

                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Price updated for ${product.name} at ${branch.name}',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            _loadPrices();
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm & Save Price',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final activeBranch = _branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => _branches.isNotEmpty
          ? _branches.first
          : const Branch(
              id: '',
              name: '',
              area: '',
              address: '',
              phone: '',
              openingHours: '',
              deliveryCoverage: '',
            ),
    );

    return AdminScaffold(
      currentSection: AdminMenuSection.prices,
      title: 'Price Management Board',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadPrices,
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Branch Store: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedBranchId,
                  items: _branches.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.name} (${b.code})'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBranchId = v);
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vegetables to manage pricing...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: products.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final branchPrice = p.getPricePaiseForBranch(
                        activeBranch.id,
                      );
                      final isOverridden = branchPrice != p.basePricePaise;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.neutral200),
                        ),
                        child: ListTile(
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'SKU: ${p.sku} • Base Catalog Price: ${CurrencyFormatter.formatPaise(p.basePricePaise)} per ${p.unit}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatPaise(branchPrice),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isOverridden
                                          ? Colors.purple.shade700
                                          : AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    isOverridden
                                        ? 'Branch Override'
                                        : 'Catalog Default',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverridden
                                          ? Colors.purple.shade700
                                          : AppColors.neutral600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Update Price'),
                                onPressed: () =>
                                    _showPriceUpdateModal(p, activeBranch),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
