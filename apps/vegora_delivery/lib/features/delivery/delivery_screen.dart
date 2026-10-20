import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';
import 'package:vegora_ui/vegora_ui.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final partner = MockOrderRepository.sampleDeliveryPartner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersListProvider);

    // Orders assigned to this delivery partner
    final assignedOrders = allOrders.where((o) {
      return o.assignedDeliveryPartner?.id == partner.id ||
          o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.outForDelivery;
    }).toList();

    final activeDeliveries = assignedOrders.where((o) {
      return o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.outForDelivery;
    }).toList();

    final completedDeliveries = assignedOrders.where((o) {
      return o.status == OrderStatus.delivered;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Partner App'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: RoleIndicatorBadge(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Active Trips (${activeDeliveries.length})'),
            Tab(text: 'Completed (${completedDeliveries.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Partner Profile Card
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusOutForDelivery.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.statusOutForDelivery,
                    size: 24,
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
                            partner.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ONLINE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${partner.vehicleNumber} • Rating: ${partner.rating} ⭐',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Deliveries',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${partner.totalDeliveriesCompleted + completedDeliveries.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveriesList(activeDeliveries, isActive: true),
                _buildDeliveriesList(completedDeliveries, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList(List<Order> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return EmptyStateView(
        emoji: isActive ? '🛵' : '🏁',
        title: isActive ? 'No Active Deliveries' : 'No Completed Deliveries',
        message: isActive
            ? 'No pickup orders currently ready for you. As branch staff marks orders "Ready for Pickup", they will appear here.'
            : 'Deliveries you complete will appear in this history tab.',
      );
    }

    final timeFormat = DateFormat('hh:mm a, dd MMM');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: order.status == OrderStatus.outForDelivery
                  ? AppColors.statusOutForDelivery
                  : AppColors.border,
              width: order.status == OrderStatus.outForDelivery ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              const SizedBox(height: 12),

              // Pickup from Store
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PICKUP FROM STORE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            order.branchName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Drop to Customer
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.pin_drop_rounded,
                      size: 16,
                      color: AppColors.statusOutForDelivery,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DELIVER TO CUSTOMER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusOutForDelivery,
                            ),
                          ),
                          Text(
                            '${order.customerName} (+91 ${order.customerPhone})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryAddress.fullAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: 'Simulate Call',
                      onPressed: () {
                        VegoraToast.showInfo(
                          context,
                          'Simulated calling customer: +91 ${order.customerPhone}',
                          title: 'Calling Customer',
                          icon: Icons.phone_forwarded_rounded,
                        );
                      },
                    ),
                  ],
                ),
              ),

              if (order.deliveryInstructions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Customer Note: "${order.deliveryInstructions}"',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              const Divider(height: 20),

              // Items summary & Payment collect
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} items (${order.items.fold(0, (s, i) => s + i.quantity)} units)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Payment: ${order.paymentMethod}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Collect Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(order.totalPaise),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (isActive) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: _buildDeliveryActionButton(context, ref, order),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryActionButton(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) {
    if (order.status == OrderStatus.readyForPickup) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.electric_moped_rounded, size: 18),
        label: const Text(
          'Pick Up & Start Delivery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusOutForDelivery,
        ),
        onPressed: () {
          ref
              .read(ordersListProvider.notifier)
              .updateStatus(
                order.id,
                OrderStatus.outForDelivery,
                reason:
                    'Delivery partner picked up package from ${order.branchName} and is en-route',
                deliveryPartner: partner,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order ${order.orderNumber} is now Out for Delivery!',
              ),
            ),
          );
        },
      );
    } else if (order.status == OrderStatus.outForDelivery) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text(
          'Confirm Doorstep Delivery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusDelivered,
        ),
        onPressed: () => _confirmDelivered(context, ref, order),
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmDelivered(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Complete Delivery?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Handing over package ${order.orderNumber} to ${order.customerName}.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to collect:'),
                    Text(
                      order.paymentMethod == 'Cash on Delivery'
                          ? CurrencyFormatter.formatPaise(order.totalPaise)
                          : 'PAID ONLINE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: order.paymentMethod == 'Cash on Delivery'
                            ? AppColors.primaryDark
                            : AppColors.primary,
                      ),
                    ),
                  ],
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
                backgroundColor: AppColors.statusDelivered,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(ordersListProvider.notifier)
                    .updateStatus(
                      order.id,
                      OrderStatus.delivered,
                      reason:
                          'Safely delivered to customer doorstep at ${DateFormat('hh:mm a').format(DateTime.now())}',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order ${order.orderNumber} marked Delivered!',
                    ),
                  ),
                );
              },
              child: const Text('Mark as Delivered'),
            ),
          ],
        );
      },
    );
  }
}
