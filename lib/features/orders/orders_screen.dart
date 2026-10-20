import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
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
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    final activeOrders = customerOrders
        .where((o) => !o.status.isTerminal)
        .toList();

    final pastOrders = customerOrders
        .where((o) => o.status.isTerminal)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTamil ? 'என் ஆர்டர்கள்' : 'My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: isTamil
                  ? 'நடப்பில் உள்ளவை (${activeOrders.length})'
                  : 'Active (${activeOrders.length})',
            ),
            Tab(
              text: isTamil
                  ? 'முடிந்தவை (${pastOrders.length})'
                  : 'Past Orders (${pastOrders.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(
            activeOrders,
            isActive: true,
            isTamil: isTamil,
            localeCode: locale.languageCode,
          ),
          _buildOrdersList(
            pastOrders,
            isActive: false,
            isTamil: isTamil,
            localeCode: locale.languageCode,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    List<Order> orders, {
    required bool isActive,
    required bool isTamil,
    required String localeCode,
  }) {
    if (orders.isEmpty) {
      return EmptyStateView(
        emoji: isActive ? '📦' : '🧾',
        title: isActive
            ? (isTamil ? 'நடப்பு ஆர்டர்கள் எதுவும் இல்லை' : 'No Active Orders')
            : (isTamil ? 'கடந்த ஆர்டர்கள் எதுவும் இல்லை' : 'No Past Orders'),
        message: isActive
            ? (isTamil
                  ? 'தற்போது செயலில் உள்ள ஆர்டர்கள் எதுவும் இல்லை. புதிய காய்கறிகளை உடனே ஆர்டர் செய்யுங்கள்!'
                  : 'You have no orders currently in progress. Fresh vegetables are just a few taps away!')
            : (isTamil
                  ? 'உங்கள் கடந்த கால ஆர்டர்கள் மற்றும் ரசீதுகள் இங்கு காண்பிக்கப்படும்.'
                  : 'Your past delivered or cancelled orders will appear here.'),
        buttonText: isActive
            ? (isTamil ? 'காய்கறிகளை வாங்குக' : 'Start Shopping')
            : null,
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
                      .map(
                        (i) =>
                            '${i.formattedQuantity(isTamil: isTamil)} ${i.product.displayName(localeCode)}',
                      )
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: isTamil ? 1.35 : 1.2,
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
                        Text(
                          isTamil ? 'செலுத்திய தொகை' : 'Total Paid',
                          style: const TextStyle(
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
