import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

class AdminPromotionsScreen extends ConsumerStatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  ConsumerState<AdminPromotionsScreen> createState() =>
      _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends ConsumerState<AdminPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Promotion> _promotions = [];
  List<Branch> _branches = [];
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      if (catalogRepo is SupabaseCatalogRepository) {
        final promos = await catalogRepo.getAllPromotions(
          includeInactive: true,
        );
        final cats = await catalogRepo.getAllCategories(includeInactive: true);
        final brs = await (branchRepo is SupabaseBranchRepository
            ? branchRepo.getAllBranches(includeInactive: false)
            : branchRepo.getBranches());

        if (mounted) {
          setState(() {
            _promotions = promos;
            _categories = cats;
            _branches = brs;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading promotions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePromotionModal({bool isUrgentSale = false}) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(
      text: isUrgentSale
          ? 'URGENT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
          : '',
    );
    final titleCtrl = TextEditingController(
      text: isUrgentSale ? 'Urgent Harvest Fresh Clearance' : '',
    );
    final descCtrl = TextEditingController(
      text: isUrgentSale
          ? 'Farm surplus harvested today. Enjoy extra fresh greens at steep discounts!'
          : '',
    );
    String discountType = 'percentage'; // 'percentage' or 'fixed'
    final discountValCtrl = TextEditingController(
      text: isUrgentSale ? '25' : '10',
    );
    final minOrderCtrl = TextEditingController(text: '0');
    final maxDiscountCtrl = TextEditingController(text: '');
    String? selectedBranchId;
    String? selectedCategoryId;
    DateTime startTime = DateTime.now();
    DateTime endTime = isUrgentSale
        ? DateTime.now().add(const Duration(hours: 24))
        : DateTime.now().add(const Duration(days: 14));

    bool isSaving = false;
    String? modalError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isUrgentSale
                    ? Icons.flash_on_rounded
                    : Icons.local_offer_rounded,
                color: isUrgentSale ? Colors.amber.shade800 : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                isUrgentSale
                    ? 'Launch Urgent Clearance Sale'
                    : 'Create Promotion Code',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (modalError != null)
                      Text(
                        modalError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Coupon / Promo Code *',
                              hintText: 'e.g. FESTIVE20',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Code required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Promotion Title *',
                              hintText: 'e.g. 20% Off Weekend Greens',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Title required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description / Terms',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: discountType,
                            decoration: const InputDecoration(
                              labelText: 'Discount Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Percentage (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Flat Amount (₹)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => discountType = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: discountValCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: discountType == 'percentage'
                                  ? 'Discount (%) *'
                                  : 'Discount (₹) *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v.trim());
                              if (n == null || n <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: selectedBranchId,
                            decoration: const InputDecoration(
                              labelText: 'Branch Limitation',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Branches (Network-wide)'),
                              ),
                              for (final b in _branches)
                                DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.name} (${b.code})'),
                                ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedBranchId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category Limitation',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Vegetable Categories'),
                              ),
                              for (final c in _categories)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text('${c.emoji} ${c.name}'),
                                ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedCategoryId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Order Amount (₹)',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: maxDiscountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Discount Cap (₹)',
                              prefixText: '₹ ',
                              hintText: 'Optional',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Valid until: ${DateFormat.yMMMd().add_jm().format(endTime)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: endTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  endTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    23,
                                    59,
                                  );
                                });
                              }
                            },
                            child: const Text('Change Date'),
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
                backgroundColor: isUrgentSale
                    ? Colors.amber.shade800
                    : AppColors.primary,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        modalError = null;
                      });

                      try {
                        final repo = ref.read(catalogRepositoryProvider);
                        if (repo is! SupabaseCatalogRepository) return;

                        final discValNum =
                            double.tryParse(discountValCtrl.text.trim()) ?? 0;
                        final minOrderPaise =
                            ((double.tryParse(minOrderCtrl.text.trim()) ?? 0) *
                                    100)
                                .round();
                        final maxDiscPaise =
                            maxDiscountCtrl.text.trim().isNotEmpty
                            ? ((double.tryParse(maxDiscountCtrl.text.trim()) ??
                                          0) *
                                      100)
                                  .round()
                            : null;

                        final promoPayload = Promotion(
                          id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
                          code: codeCtrl.text.trim().toUpperCase(),
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          discountType: discountType,
                          discountValue: discountType == 'percentage'
                              ? discValNum.round()
                              : (discValNum * 100).round(),
                          minOrderAmountPaise: minOrderPaise,
                          maxDiscountPaise: maxDiscPaise,
                          branchId: selectedBranchId,
                          categoryId: selectedCategoryId,
                          isUrgentSale: isUrgentSale,
                          startTime: startTime,
                          endTime: endTime,
                          isActive: true,
                        );

                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        await repo.createPromotion(promoPayload);

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Promotion "${promoPayload.code}" published successfully!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadData();
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isUrgentSale ? 'Launch Clearance Deal' : 'Publish Coupon',
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

  @override
  Widget build(BuildContext context) {
    final standardPromos = _promotions.where((p) => !p.isUrgentSale).toList();
    final urgentSales = _promotions.where((p) => p.isUrgentSale).toList();

    return AdminScaffold(
      currentSection: AdminMenuSection.promotions,
      title: 'Discounts & Urgent Clearance',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 380,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.neutral600,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Standard Coupons (${standardPromos.length})'),
                      Tab(text: '⚡ Urgent Clearance (${urgentSales.length})'),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  label: const Text('⚡ Urgent Clearance Deal'),
                  onPressed: () =>
                      _showCreatePromotionModal(isUrgentSale: true),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('+ New Promotion'),
                  onPressed: () =>
                      _showCreatePromotionModal(isUrgentSale: false),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPromoList(standardPromos),
                      _buildPromoList(urgentSales, isUrgentTab: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoList(List<Promotion> list, {bool isUrgentTab = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUrgentTab ? Icons.flash_on_rounded : Icons.local_offer_rounded,
              size: 56,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 12),
            Text(
              isUrgentTab
                  ? 'No active urgent clearance sales.'
                  : 'No promotions configured.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  _showCreatePromotionModal(isUrgentSale: isUrgentTab),
              child: Text(
                isUrgentTab ? 'Launch Urgent Clearance' : 'Create Promotion',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = list[index];
        final isExpired = p.isExpired;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isUrgentTab
                  ? Colors.amber.withValues(alpha: 0.6)
                  : isExpired
                  ? AppColors.neutral300
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isUrgentTab
                  ? Colors.amber.shade100
                  : isExpired
                  ? AppColors.neutral200
                  : AppColors.primaryContainer,
              child: Icon(
                isUrgentTab
                    ? Icons.flash_on_rounded
                    : Icons.local_offer_rounded,
                color: isUrgentTab
                    ? Colors.amber.shade900
                    : isExpired
                    ? AppColors.neutral600
                    : AppColors.primary,
              ),
            ),
            title: Row(
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${p.discountType == "percentage" ? "${p.discountValue}% OFF" : "${CurrencyFormatter.formatPaise(p.discountValue)} FLAT OFF"} • Min: ${CurrencyFormatter.formatPaise(p.minOrderAmountPaise)} • Ends: ${DateFormat.yMMMd().format(p.endTime)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? AppColors.neutral200
                        : p.isActive
                        ? Colors.green.shade100
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired
                        ? 'EXPIRED'
                        : p.isActive
                        ? 'ACTIVE'
                        : 'PAUSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? AppColors.neutral600
                          : p.isActive
                          ? Colors.green.shade800
                          : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Switch(
                  value: p.isActive && !isExpired,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: isExpired
                      ? null
                      : (val) async {
                          final repo = ref.read(catalogRepositoryProvider);
                          if (repo is SupabaseCatalogRepository) {
                            await repo.togglePromotionActive(p.id, val);
                            _loadData();
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
