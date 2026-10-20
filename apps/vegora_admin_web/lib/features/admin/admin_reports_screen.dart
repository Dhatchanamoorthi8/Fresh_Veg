import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isLoading = true;
  List<Branch> _branches = [];
  String? _selectedBranchId;
  Map<String, dynamic> _report = {};
  List<Map<String, dynamic>> _bestsellers = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      final brs = await (branchRepo is SupabaseBranchRepository
          ? branchRepo.getAllBranches(includeInactive: false)
          : branchRepo.getBranches());

      if (orderRepo is SupabaseOrderRepository) {
        final rep = await orderRepo.getSalesReport(branchId: _selectedBranchId);
        final top = await orderRepo.getBestsellingReport(
          branchId: _selectedBranchId,
          limit: 10,
        );

        if (mounted) {
          setState(() {
            _branches = brs;
            _report = rep;
            _bestsellers = top;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentSection: AdminMenuSection.reports,
      title: 'Sales & Performance Reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadReport,
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
                const Icon(Icons.analytics_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Branch Filter: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedBranchId,
                  hint: const Text('All Branch Outlets (Consolidated)'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Branch Outlets (Consolidated)'),
                    ),
                    for (final b in _branches)
                      DropdownMenuItem(
                        value: b.id,
                        child: Text('${b.name} (${b.code})'),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedBranchId = v);
                    _loadReport();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Gross Revenue',
                              CurrencyFormatter.formatPaise(
                                _report['total_revenue_paise'] ?? 0,
                              ),
                              Icons.currency_rupee_rounded,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricCard(
                              'Delivered Orders',
                              '${_report['delivered_orders_count'] ?? 0}',
                              Icons.task_alt_rounded,
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricCard(
                              'Average Order Value',
                              CurrencyFormatter.formatPaise(
                                _report['average_order_value_paise'] ?? 0,
                              ),
                              Icons.trending_up_rounded,
                              Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricCard(
                              'Total Items Harvested',
                              '${_report['total_items_sold'] ?? 0}',
                              Icons.grass_rounded,
                              Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Top 10 Bestselling Vegetables (By Units Sold)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_bestsellers.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No completed deliveries recorded in this period yet.',
                              ),
                            ),
                          ),
                        )
                      else
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.neutral200),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _bestsellers.length,
                            separatorBuilder: (ctx, idx) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _bestsellers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryContainer,
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['product_name'] ?? 'Vegetable',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Units Sold: ${item['total_quantity_sold']} ${item['unit'] ?? ""}',
                                ),
                                trailing: Text(
                                  CurrencyFormatter.formatPaise(
                                    item['total_sales_paise'] ?? 0,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
