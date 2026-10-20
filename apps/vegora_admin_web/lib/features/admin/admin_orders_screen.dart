import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Order> _orders = [];
  List<Branch> _branches = [];
  String? _selectedBranchId;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      final brs = await (branchRepo is SupabaseBranchRepository
          ? branchRepo.getAllBranches(includeInactive: false)
          : branchRepo.getBranches());

      if (orderRepo is SupabaseOrderRepository) {
        final list = _selectedBranchId == null
            ? await orderRepo.getAllOrders()
            : await orderRepo.getBranchOrders(_selectedBranchId!);
        final filteredList = _statusFilter == 'ALL'
            ? list
            : list.where((o) => o.status.rawValue == _statusFilter).toList();
        if (mounted) {
          setState(() {
            _orders = filteredList;
            _branches = brs;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Customer: ${order.customerName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Phone: ${order.customerPhone}',
                style: const TextStyle(color: AppColors.neutral700),
              ),
              Text(
                'Address: ${order.deliveryAddressText}',
                style: const TextStyle(color: AppColors.neutral700),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items Ordered:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ${item.product.name} (${item.product.unit})',
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.formatPaise(item.totalPaise),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    CurrencyFormatter.formatPaise(order.totalPaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Transition Order Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in [
                    OrderStatus.accepted,
                    OrderStatus.preparing,
                    OrderStatus.readyForPickup,
                    OrderStatus.outForDelivery,
                    OrderStatus.delivered,
                    OrderStatus.cancelled,
                  ])
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: order.status == status
                            ? AppColors.primary
                            : AppColors.neutral200,
                        foregroundColor: order.status == status
                            ? Colors.white
                            : AppColors.neutral800,
                      ),
                      onPressed: order.status == status
                          ? null
                          : () async {
                              final repo = ref.read(orderRepositoryProvider);
                              if (repo is SupabaseOrderRepository) {
                                await repo.updateOrderStatus(order.id, status);
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadOrders();
                              }
                            },
                      child: Text(status.displayName),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case OrderStatus.newOrder:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case OrderStatus.outForDelivery:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        break;
      case OrderStatus.delivered:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentSection: AdminMenuSection.orders,
      title: 'Customer Orders',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadOrders,
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
                DropdownButton<String?>(
                  value: _selectedBranchId,
                  hint: const Text('All Branches'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Branches'),
                    ),
                    for (final b in _branches)
                      DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedBranchId = v);
                    _loadOrders();
                  },
                ),
                const SizedBox(width: 14),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'NEW', child: Text('New Orders')),
                    DropdownMenuItem(
                      value: 'ACCEPTED',
                      child: Text('Accepted'),
                    ),
                    DropdownMenuItem(value: 'PACKED', child: Text('Packed')),
                    DropdownMenuItem(
                      value: 'OUT_FOR_DELIVERY',
                      child: Text('Out for Delivery'),
                    ),
                    DropdownMenuItem(
                      value: 'DELIVERED',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELLED',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _statusFilter = v);
                      _loadOrders();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? const Center(
                    child: Text('No orders recorded under this filter.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _orders.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final o = _orders[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.neutral200),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                '#${o.orderNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                o.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${o.items.length} items • ${o.deliverySlot} • ${DateFormat.yMMMd().format(o.createdAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyFormatter.formatPaise(o.totalPaise),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusBadge(o.status),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.neutral400,
                              ),
                            ],
                          ),
                          onTap: () => _showOrderDetails(o),
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
