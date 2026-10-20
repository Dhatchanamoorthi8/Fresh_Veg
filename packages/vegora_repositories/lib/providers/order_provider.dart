import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_models/vegora_models.dart';

import 'app_providers.dart';
import 'auth_provider.dart';

final ordersListProvider = NotifierProvider<OrdersListNotifier, List<Order>>(
  () {
    return OrdersListNotifier();
  },
);

class OrdersListNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    fetchOrders();
    return [];
  }

  Future<void> fetchOrders() async {
    final repo = ref.read(orderRepositoryProvider);
    try {
      final list = await repo.getAllOrders();
      state = list;
    } catch (_) {
      // In case user doesn't have admin rights, fetch customer orders
      final phone = ref.read(customerPhoneProvider) ?? '';
      final list = await repo.getCustomerOrders(phone);
      state = list;
    }
  }

  Future<Order> placeOrder(Order order) async {
    final repo = ref.read(orderRepositoryProvider);
    final created = await repo.createOrder(order);
    state = [created, ...state.where((o) => o.id != created.id)];
    return created;
  }

  Future<void> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    DeliveryPartner? deliveryPartner,
  }) async {
    final repo = ref.read(orderRepositoryProvider);
    final updated = await repo.updateOrderStatus(
      orderId,
      newStatus,
      rejectionReason: reason,
      deliveryPartner: deliveryPartner,
    );

    state = state.map((o) => o.id == orderId ? updated : o).toList();
  }

  Future<void> cancelOrder(
    String orderId, {
    String reason = 'Cancelled by customer',
  }) async {
    final repo = ref.read(orderRepositoryProvider);
    final updated = await repo.cancelOrder(orderId, reason: reason);
    state = state.map((o) => o.id == orderId ? updated : o).toList();
  }
}

/// Active customer orders derived from orders list
final customerOrdersProvider = Provider<List<Order>>((ref) {
  final allOrders = ref.watch(ordersListProvider);
  final phone = ref.watch(customerPhoneProvider);
  if (phone == null || phone.isEmpty) return allOrders;
  return allOrders.where((o) => o.customerPhone == phone).toList();
});

/// Orders for a specific store branch
final branchOrdersProvider = FutureProvider.family<List<Order>, String>((
  ref,
  branchId,
) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getBranchOrders(branchId);
});

/// Orders assigned to delivery partner
final deliveryOrdersProvider = FutureProvider.family<List<Order>, String>((
  ref,
  deliveryPartnerId,
) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getDeliveryOrders(deliveryPartnerId);
});

/// Specific order by ID (synchronous from in-memory orders list)
final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  final orders = ref.watch(ordersListProvider);
  return orders.where((o) => o.id == orderId).firstOrNull;
});
