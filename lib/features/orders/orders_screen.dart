import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/order.dart';
import '../../shared/models/order_status.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/order_status_badge.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final customerOrders = ref.watch(customerOrdersProvider);

    final activeOrders = customerOrders
        .where((o) => !o.status.isTerminal)
        .toList();

    final pastOrders = customerOrders
        .where((o) => o.status.isTerminal)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Active (${activeOrders.length})'),
            Tab(text: 'Past Orders (${pastOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(activeOrders, isActive: true),
          _buildOrdersList(pastOrders, isActive: false),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return EmptyStateView(
        emoji: isActive ? '📦' : '🧾',
        title: isActive ? 'No Active Orders' : 'No Past Orders',
        message: isActive
            ? 'You have no orders currently in progress. Fresh vegetables are just a few taps away!'
            : 'Your past delivered or cancelled orders will appear here.',
        buttonText: isActive ? 'Start Shopping' : null,
        onButtonPressed: isActive ? () => context.go('/home') : null,
      );
    }

    final timeFormat = DateFormat('hh:mm a, dd MMM yyyy');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];

        return InkWell(
          onTap: () => context.push('/tracking/${order.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    OrderStatusBadge(status: order.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(order.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),

                const SizedBox(height: 12),

                // Store Branch info
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.branchName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items preview string
                Text(
                  order.items
                      .map((i) => '${i.quantity}x ${i.product.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Divider(height: 20),

                // Total and Track Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(order.totalPaise),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          isActive ? 'Track Live' : 'View Details',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
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
