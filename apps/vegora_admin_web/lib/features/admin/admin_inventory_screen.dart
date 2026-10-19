import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';
import 'package:vegora_ui/vegora_ui.dart';
import 'admin_shell.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() =>
      _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  bool _isLoading = true;
  List<Branch> _branches = [];
  String? _selectedBranchId;
  List<Product> _allProducts = [];
  String _stockFilter = 'ALL'; // 'ALL', 'LOW_STOCK', 'OUT_OF_STOCK', 'IN_STOCK'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final branchRepo = ref.read(branchRepositoryProvider);
      final catalogRepo = ref.read(catalogRepositoryProvider);

      final brs = await (branchRepo is SupabaseBranchRepository
          ? branchRepo.getAllBranches(includeInactive: false)
          : branchRepo.getBranches());

      if (catalogRepo is SupabaseCatalogRepository) {
        final prods = await catalogRepo.getAdminProducts();
        if (mounted) {
          setState(() {
            _branches = brs;
            if (_selectedBranchId == null && brs.isNotEmpty) {
              _selectedBranchId = brs.first.id;
            }
            _allProducts = prods;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load inventory: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredBranchProducts {
    if (_selectedBranchId == null) return [];

    return _allProducts.where((p) {
      final inv = p.branchInventory[_selectedBranchId];
      final stock = inv?.stockQuantity ?? 0;
      final threshold = inv?.lowStockThreshold ?? 5;
      final isAvailable = inv?.isAvailable ?? false;

      if (_stockFilter == 'OUT_OF_STOCK' && stock > 0 && isAvailable) {
        return false;
      }
      if (_stockFilter == 'LOW_STOCK' && (stock > threshold || stock == 0)) {
        return false;
      }
      if (_stockFilter == 'IN_STOCK' && (stock == 0 || !isAvailable)) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        return matchName || matchSku;
      }
      return true;
    }).toList();
  }

  void _showAddVegetableToBranchModal() {
    if (_selectedBranchId == null) return;
    final selectedBranch = _branches.firstWhere(
      (b) => b.id == _selectedBranchId,
    );

    // Filter products that don't have an entry in this branch inventory yet
    final availableToAdd = _allProducts.where((p) {
      return !p.branchInventory.containsKey(_selectedBranchId);
    }).toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All catalog vegetables are already stocked in this branch.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    Product? selectedProduct = availableToAdd.first;
    final priceCtrl = TextEditingController(
      text: (selectedProduct.basePricePaise / 100).toStringAsFixed(0),
    );
    final stockCtrl = TextEditingController(text: '30');
    final thresholdCtrl = TextEditingController(text: '5');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Add Vegetable to ${selectedBranch.name}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Product>(
                  initialValue: selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Select Vegetable from Catalog',
                    border: OutlineInputBorder(),
                  ),
                  items: availableToAdd.map((p) {
                    final label = p.nameTa.isNotEmpty
                        ? '${p.name} (${p.nameTa}) - ${p.unit}'
                        : '${p.name} (${p.unit})';
                    return DropdownMenuItem(
                      value: p,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedProduct = v;
                        priceCtrl.text = (v.basePricePaise / 100)
                            .toStringAsFixed(0);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Branch Selling Price (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: (selectedProduct?.isWeightBased ?? true)
                              ? 'Initial Stock (kg)'
                              : 'Initial Stock (pcs)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: thresholdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: (selectedProduct?.isWeightBased ?? true)
                        ? 'Low Stock Alert (kg)'
                        : 'Low Stock Alert (pcs)',
                    hintText: '5',
                    border: const OutlineInputBorder(),
                  ),
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
                      if (selectedProduct == null) return;
                      setDialogState(() => isSaving = true);
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final repo = ref.read(catalogRepositoryProvider);
                        if (repo is! SupabaseCatalogRepository) return;

                        final priceVal =
                            double.tryParse(priceCtrl.text.trim()) ?? 0;
                        final stockNum =
                            double.tryParse(stockCtrl.text.trim()) ?? 0;
                        final thresholdNum =
                            double.tryParse(thresholdCtrl.text.trim()) ?? 5;

                        final isWeight = selectedProduct!.isWeightBased;
                        final stockVal = isWeight
                            ? (stockNum * 1000).round()
                            : stockNum.round();
                        final thresholdVal = isWeight
                            ? (thresholdNum * 1000).round()
                            : thresholdNum.round();

                        if (stockVal < 0) {
                          throw Exception('Stock cannot be negative.');
                        }

                        await repo.updateBranchInventoryPricingAndStock(
                          branchId: _selectedBranchId!,
                          productId: selectedProduct!.id,
                          pricePaise: (priceVal * 100).round(),
                          stockQuantity: stockVal,
                          lowStockThreshold: thresholdVal,
                          isAvailable: stockVal > 0,
                        );

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${selectedProduct!.name} to ${selectedBranch.name}',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadData();
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
                      'Add to Branch',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(Product product) {
    if (_selectedBranchId == null) return;
    final inv = product.branchInventory[_selectedBranchId];
    final currentPrice = inv?.pricePaise ?? product.basePricePaise;
    final currentStock = inv?.stockQuantity ?? 0;
    final currentThreshold = inv?.lowStockThreshold ?? (product.isWeightBased ? 5000 : 5);

    final isWeight = product.isWeightBased;
    final displayStock = isWeight
        ? (currentStock >= 1000
            ? (currentStock / 1000).toStringAsFixed(currentStock % 1000 == 0 ? 0 : 1)
            : currentStock.toString())
        : currentStock.toString();
    final displayThreshold = isWeight
        ? (currentThreshold >= 1000
            ? (currentThreshold / 1000).toStringAsFixed(currentThreshold % 1000 == 0 ? 0 : 1)
            : currentThreshold.toString())
        : currentThreshold.toString();

    final priceCtrl = TextEditingController(
      text: (currentPrice / 100).toStringAsFixed(0),
    );
    final stockCtrl = TextEditingController(text: displayStock);
    final thresholdCtrl = TextEditingController(text: displayThreshold);
    bool isAvailable = inv?.isAvailable ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Adjust Stock: ${product.name}${product.nameTa.isNotEmpty ? " (${product.nameTa})" : ""}',
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isWeight
                              ? 'Stock in Kilograms (kg)'
                              : 'Stock Units (pcs)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: thresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isWeight
                              ? 'Low Stock Alert (kg)'
                              : 'Low Stock Alert (pcs)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isWeight) ...[
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Weight is normalized to integer grams in the backend (e.g. 25 kg = 25,000 g).',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Branch Selling Price (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for Purchase at this Branch'),
                  value: isAvailable,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setDialogState(() => isAvailable = v),
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
                      setDialogState(() => isSaving = true);
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final repo = ref.read(catalogRepositoryProvider);
                        if (repo is! SupabaseCatalogRepository) return;

                        final priceVal =
                            double.tryParse(priceCtrl.text.trim()) ?? 0;
                        final stockNum =
                            double.tryParse(stockCtrl.text.trim()) ?? 0;
                        final thresholdNum =
                            double.tryParse(thresholdCtrl.text.trim()) ??
                                (isWeight ? 5.0 : 5.0);

                        final stockVal = isWeight
                            ? (stockNum * 1000).round()
                            : stockNum.round();
                        final thresholdVal = isWeight
                            ? (thresholdNum * 1000).round()
                            : thresholdNum.round();

                        if (stockVal < 0) {
                          throw Exception('Stock quantity cannot be negative.');
                        }

                        await repo.updateBranchInventoryPricingAndStock(
                          branchId: _selectedBranchId!,
                          productId: product.id,
                          pricePaise: (priceVal * 100).round(),
                          stockQuantity: stockVal,
                          lowStockThreshold: thresholdVal,
                          isAvailable: isAvailable && stockVal > 0,
                        );

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Branch inventory updated!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadData();
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
                      'Update Stock',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredBranchProducts;

    return AdminScaffold(
      currentSection: AdminMenuSection.inventory,
      title: 'Branch Inventory Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
        ),
      ],
      body: Column(
        children: [
          // Branch selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Active Branch:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
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
                      hintText: 'Search inventory by name, SKU...',
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
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _stockFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text('All Stock Levels'),
                    ),
                    DropdownMenuItem(
                      value: 'LOW_STOCK',
                      child: Text('Low Stock Alerts (< 5)'),
                    ),
                    DropdownMenuItem(
                      value: 'OUT_OF_STOCK',
                      child: Text('Out of Stock (0)'),
                    ),
                    DropdownMenuItem(
                      value: 'IN_STOCK',
                      child: Text('Healthy Stock'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _stockFilter = v);
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6B3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Stock Vegetable',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _showAddVegetableToBranchModal,
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 64,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: 16),
                        const Text('No inventory items match filter.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showAddVegetableToBranchModal,
                          child: const Text('Stock a Vegetable Here'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: products.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final inv = p.branchInventory[_selectedBranchId];
                      final stock = inv?.stockQuantity ?? 0;
                      final threshold = inv?.lowStockThreshold ?? 5;
                      final price = inv?.pricePaise ?? p.basePricePaise;
                      final isAvail = (inv?.isAvailable ?? false) && stock > 0;

                      final isLow = stock > 0 && stock <= threshold;
                      final isOut = stock == 0 || !isAvail;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isOut
                                ? AppColors.error.withValues(alpha: 0.5)
                                : isLow
                                ? Colors.orange.withValues(alpha: 0.5)
                                : AppColors.neutral200,
                          ),
                        ),
                        child: ListTile(
                          leading: ProductImageView(
                            imageUrl: p.imageUrl,
                            fallbackEmoji: p.emoji,
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(
                            p.nameTa.isNotEmpty ? '${p.name} (${p.nameTa})' : p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'SKU: ${p.sku} • Unit: ${p.formatUnitLabel()} • Alert: ${p.formatQuantity(threshold)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatPaise(price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOut
                                          ? AppColors.error.withValues(
                                              alpha: 0.1,
                                            )
                                          : isLow
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOut
                                          ? 'Out of Stock'
                                          : isLow
                                          ? 'Low Stock (${p.formatQuantity(stock)})'
                                          : '${p.formatQuantity(stock)} in stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isOut
                                            ? AppColors.error
                                            : isLow
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Adjust Stock & Pricing',
                                onPressed: () => _showUpdateStockDialog(p),
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
