import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/branch.dart';
import '../../shared/models/product.dart';
import '../../shared/models/promotion.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/repositories/supabase_branch_repository.dart';
import '../../shared/repositories/supabase_catalog_repository.dart';
import '../../shared/repositories/supabase_order_repository.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String? _selectedBranchId; // null = consolidated
  bool _isLoading = true;

  Map<String, dynamic> _salesMetrics = {};
  List<Map<String, dynamic>> _bestsellers = [];
  List<Product> _clearanceProducts = [];
  List<Branch> _branches = [];
  List<Promotion> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      if (orderRepo is SupabaseOrderRepository) {
        _salesMetrics = await orderRepo.getSalesReport(
          branchId: _selectedBranchId,
        );
        _bestsellers = await orderRepo.getBestsellingReport(
          branchId: _selectedBranchId,
          limit: 6,
        );
      }

      if (catalogRepo is SupabaseCatalogRepository) {
        _clearanceProducts = await catalogRepo.getUrgentClearanceProducts(
          branchId: _selectedBranchId,
        );
        _promotions = await catalogRepo.getAllPromotions();
      }

      final brs = await (branchRepo is SupabaseBranchRepository
          ? branchRepo.getAllBranches(includeInactive: true)
          : branchRepo.getBranches());
      _branches = brs;
    } catch (e) {
      debugPrint('Error loading admin metrics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentSection: AdminMenuSection.dashboard,
      title: 'Operations Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Metrics',
          onPressed: _loadDashboardData,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Quick Action Bar
                _buildQuickActionBar(context),
                const SizedBox(height: 20),

                // Top KPIs
                _buildKpiRow(),
                const SizedBox(height: 24),

                // Operational Sections Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isWide ? 6 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStoreNetworkCard(context),
                              const SizedBox(height: 20),
                              _buildClearanceDealsCard(context),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
                        if (isWide)
                          Expanded(flex: 5, child: _buildBestsellersCard()),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions & Management',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              DropdownButton<String?>(
                value: _selectedBranchId,
                hint: const Text('All Branches (Consolidated)'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Branches (Consolidated)'),
                  ),
                  for (final b in _branches)
                    DropdownMenuItem(value: b.id, child: Text(b.name)),
                ],
                onChanged: (v) {
                  setState(() => _selectedBranchId = v);
                  _loadDashboardData();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text(
                  '+ Add Branch',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.go('/admin/branches'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.eco_rounded, size: 18),
                label: const Text(
                  '+ Add Vegetable',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.go('/admin/vegetables'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('Branch Inventory'),
                onPressed: () => context.go('/admin/inventory'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.price_change_rounded, size: 18),
                label: const Text('Price Board'),
                onPressed: () => context.go('/admin/prices'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.local_offer_rounded, size: 18),
                label: const Text('Promotions & Urgent Deals'),
                onPressed: () => context.go('/admin/promotions'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Customer Orders'),
                onPressed: () => context.go('/admin/orders'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final rev = _salesMetrics['total_revenue_paise'] ?? 0;
    final ord = _salesMetrics['delivered_orders_count'] ?? 0;
    final aov = _salesMetrics['average_order_value_paise'] ?? 0;
    final activeBranches = _branches.where((b) => b.isActive).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Revenue',
            CurrencyFormatter.formatPaise(rev),
            Icons.currency_rupee_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricTile(
            'Completed Deliveries',
            '$ord',
            Icons.task_alt_rounded,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricTile(
            'Avg Order Value',
            CurrencyFormatter.formatPaise(aov),
            Icons.trending_up_rounded,
            Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricTile(
            'Active Store Hubs',
            '$activeBranches Stores',
            Icons.store_rounded,
            Colors.teal.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreNetworkCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Store Branches Network',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/branches'),
                  child: const Text('Manage All Branches →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final b in _branches.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: b.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${b.name} (${b.code})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      b.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: b.isOpen
                            ? AppColors.primary
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearanceDealsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harvest Clearance & Promotions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/promotions'),
                  child: const Text('View All Deals →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_promotions.isEmpty && _clearanceProducts.isEmpty)
              const Text('No promotions or clearance items active.')
            else ...[
              for (final p in _promotions.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        p.isUrgentSale
                            ? Icons.flash_on_rounded
                            : Icons.local_offer_rounded,
                        size: 16,
                        color: p.isUrgentSale
                            ? Colors.amber.shade800
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${p.code} - ${p.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        p.discountType == 'percentage'
                            ? '${p.discountValue}% OFF'
                            : 'FLAT OFF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final v in _clearanceProducts.take(2))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Urgent Stock: ${v.name} (${v.unit})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(v.basePricePaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBestsellersCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Bestsellers (Units Delivered)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_bestsellers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No completed deliveries recorded yet.'),
                ),
              )
            else
              for (int i = 0; i < _bestsellers.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _bestsellers[i]['product_name'] ?? 'Vegetable',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${_bestsellers[i]['total_quantity_sold']} units',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
