import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/order.dart';
import '../../shared/models/order_status.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/order_status_badge.dart';
import '../../shared/widgets/role_picker_sheet.dart';

class BranchStaffScreen extends ConsumerStatefulWidget {
  const BranchStaffScreen({super.key});

  @override
  ConsumerState<BranchStaffScreen> createState() => _BranchStaffScreenState();
}

class _BranchStaffScreenState extends ConsumerState<BranchStaffScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final staffBranch = ref.watch(staffSelectedBranchProvider);
    final branchesAsync = ref.watch(branchesListProvider);
    final allOrders = ref.watch(ordersListProvider);

    // Filter orders by staff selected branch ONLY
    final branchOrders = allOrders
        .where((o) => o.branchId == staffBranch.id)
        .toList();

    // Calculate metrics
    final totalCount = branchOrders.length;
    final newCount = branchOrders
        .where((o) => o.status == OrderStatus.newOrder)
        .length;
    final acceptedCount = branchOrders
        .where((o) => o.status == OrderStatus.accepted)
        .length;
    final preparingCount = branchOrders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final readyCount = branchOrders
        .where((o) => o.status == OrderStatus.readyForPickup)
        .length;
    final completedCount = branchOrders
        .where((o) => o.status == OrderStatus.delivered)
        .length;

    // Apply active tab filter
    List<Order> filteredOrders = branchOrders;
    if (_selectedFilter == 'NEW') {
      filteredOrders = branchOrders
          .where((o) => o.status == OrderStatus.newOrder)
          .toList();
    } else if (_selectedFilter == 'PREPARING') {
      filteredOrders = branchOrders
          .where(
            (o) =>
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.preparing,
          )
          .toList();
    } else if (_selectedFilter == 'READY') {
      filteredOrders = branchOrders
          .where((o) => o.status == OrderStatus.readyForPickup)
          .toList();
    } else if (_selectedFilter == 'COMPLETED') {
      filteredOrders = branchOrders
          .where((o) => o.status == OrderStatus.delivered)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Staff Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: RoleIndicatorBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Branch Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.store_rounded,
                  color: AppColors.statusPreparing,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Active Store: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Expanded(
                  child: branchesAsync.when(
                    data: (branches) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: staffBranch.id,
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          items: branches.map((b) {
                            return DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                '${b.name} (${b.area})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final branch = branches.firstWhere(
                                (b) => b.id == val,
                              );
                              ref
                                  .read(staffSelectedBranchProvider.notifier)
                                  .setBranch(branch);
                            }
                          },
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // KPI Metrics Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpiCard('Total', '$totalCount', AppColors.textPrimary),
                _buildKpiCard(
                  'New',
                  '$newCount',
                  AppColors.statusNew,
                  isAlert: newCount > 0,
                ),
                _buildKpiCard(
                  'Packing',
                  '$preparingCount',
                  AppColors.statusPreparing,
                ),
                _buildKpiCard(
                  'Ready',
                  '$readyCount',
                  AppColors.statusReadyForPickup,
                ),
                _buildKpiCard(
                  'Done',
                  '$completedCount',
                  AppColors.statusDelivered,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All ($totalCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('NEW', 'New ($newCount)'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'PREPARING',
                  'In Prep (${acceptedCount + preparingCount})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip('READY', 'Ready for Pickup ($readyCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETED', 'Delivered ($completedCount)'),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: filteredOrders.isEmpty
                ? EmptyStateView(
                    emoji: '🏪',
                    title: 'No Orders In This Queue',
                    message:
                        'No orders currently matching this status for ${staffBranch.name}.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildStaffOrderCard(context, ref, order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String label,
    String count,
    Color color, {
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isAlert
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: isAlert ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String title) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(title),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildStaffOrderCard(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) {
    final timeFormat = DateFormat('hh:mm a, dd MMM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status == OrderStatus.newOrder
              ? AppColors.statusNew
              : AppColors.border,
          width: order.status == OrderStatus.newOrder ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    timeFormat.format(order.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              OrderStatusBadge(status: order.status, isCompact: true),
            ],
          ),

          const SizedBox(height: 10),

          // Customer and Slot Details
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${order.customerName} (+91 ${order.customerPhone})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Delivery Slot: ${order.deliverySlot}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (order.deliveryInstructions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speaker_notes_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: ${order.deliveryInstructions}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Items summary and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} produce items (${order.items.fold(0, (s, i) => s + i.quantity)} total units)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatPaise(order.totalPaise),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons according to Staff workflow
          Row(
            children: [
              // Inspect / Checklist button
              OutlinedButton.icon(
                icon: const Icon(Icons.checklist_rounded, size: 16),
                label: const Text(
                  'Items (Checklist)',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: () => _showPackingChecklist(context, order),
              ),
              const SizedBox(width: 8),

              // Dynamic Status Action button
              Expanded(child: _buildStaffActionButton(context, ref, order)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffActionButton(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) {
    if (order.status == OrderStatus.newOrder) {
      return Row(
        children: [
          IconButton.filledTonal(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.statusCancelled,
              size: 18,
            ),
            tooltip: 'Reject Order',
            onPressed: () => _showRejectDialog(context, ref, order),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                ref
                    .read(ordersListProvider.notifier)
                    .updateStatus(
                      order.id,
                      OrderStatus.accepted,
                      reason: 'Confirmed by store staff',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.orderNumber} Accepted'),
                  ),
                );
              },
              child: const Text(
                'Accept Order',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.accepted) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.shopping_basket_rounded, size: 16),
        label: const Text('Start Packing', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusPreparing,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () {
          ref
              .read(ordersListProvider.notifier)
              .updateStatus(
                order.id,
                OrderStatus.preparing,
                reason: 'Store team is hand-picking and grading fresh items',
              );
        },
      );
    } else if (order.status == OrderStatus.preparing) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.inventory_2_rounded, size: 16),
        label: const Text(
          'Mark Ready for Pickup',
          style: TextStyle(fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusReadyForPickup,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () {
          ref
              .read(ordersListProvider.notifier)
              .updateStatus(
                order.id,
                OrderStatus.readyForPickup,
                reason: 'Bagged and sealed. Staged for delivery pickup.',
              );
        },
      );
    } else if (order.status == OrderStatus.readyForPickup) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.statusReadyForPickup.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Waiting for Delivery Partner',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.statusReadyForPickup,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          order.status.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
  }

  void _showPackingChecklist(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Packing Checklist (${order.orderNumber})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      'Store: ${order.branchName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 20),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              item.product.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} x ${item.product.unit}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity} units',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close Checklist'),
                      ),
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

  void _showRejectDialog(BuildContext context, WidgetRef ref, Order order) {
    String selectedReason = 'Produce item out of stock';
    final List<String> reasons = [
      'Produce item out of stock',
      'Items damaged or below freshness grade',
      'Store closing early due to emergency',
      'Delivery address unserviceable today',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Reject Incoming Order?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select rejection reason for customer notification:',
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedReason = val);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: reasons.map((r) {
                        return RadioListTile<String>(
                          dense: true,
                          value: r,
                          title: Text(r, style: const TextStyle(fontSize: 13)),
                          activeColor: AppColors.statusCancelled,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusCancelled,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref
                        .read(ordersListProvider.notifier)
                        .updateStatus(
                          order.id,
                          OrderStatus.rejected,
                          reason: selectedReason,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ${order.orderNumber} rejected.'),
                      ),
                    );
                  },
                  child: const Text('Confirm Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
