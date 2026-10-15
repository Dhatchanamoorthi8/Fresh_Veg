import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vegora_models/vegora_models.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client;

  SupabaseOrderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final res = await _client
          .from('orders')
          .select('''
        *,
        branches (name),
        order_items (*),
        order_status_history (*)
      ''')
          .order('created_at', ascending: false);

      return (res as List).map((json) => _mapOrderFromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      return [];
    }
  }

  @override
  Future<List<Order>> getCustomerOrders(String customerPhone) async {
    try {
      final uid = _client.auth.currentUser?.id;
      var query = _client.from('orders').select('''
        *,
        branches (name),
        order_items (*),
        order_status_history (*)
      ''');

      if (uid != null) {
        query = query.eq('customer_id', uid);
      } else {
        query = query.eq('customer_phone', customerPhone);
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((json) => _mapOrderFromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching customer orders: $e');
      return [];
    }
  }

  @override
  Future<List<Order>> getBranchOrders(String branchId) async {
    try {
      final res = await _client
          .from('orders')
          .select('''
        *,
        branches (name),
        order_items (*),
        order_status_history (*)
      ''')
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => _mapOrderFromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching branch orders: $e');
      return [];
    }
  }

  @override
  Future<List<Order>> getDeliveryOrders(String deliveryPartnerId) async {
    try {
      final uid = _client.auth.currentUser?.id ?? deliveryPartnerId;
      final res = await _client
          .from('orders')
          .select('''
        *,
        branches (name),
        order_items (*),
        order_status_history (*)
      ''')
          .or('assigned_delivery_staff_id.eq.$uid,status.eq.READY_FOR_PICKUP')
          .order('created_at', ascending: false);

      return (res as List).map((json) => _mapOrderFromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching delivery orders: $e');
      return [];
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    try {
      final uid = _client.auth.currentUser?.id ?? order.customerId;

      final itemsPayload = order.items.map((item) {
        return {'product_id': item.product.id, 'quantity': item.quantity};
      }).toList();

      // Call Atomic Transactional RPC in Supabase
      final rpcRes = await _client.rpc(
        'create_order_atomic',
        params: {
          'p_customer_id': uid,
          'p_branch_id': order.branchId,
          'p_delivery_address_id': order.deliveryAddress.id.startsWith('addr_')
              ? null
              : order.deliveryAddress.id,
          'p_customer_name': order.customerName,
          'p_customer_phone': order.customerPhone,
          'p_delivery_address_text': order.deliveryAddress.fullAddress,
          'p_payment_method': order.paymentMethod,
          'p_delivery_slot': order.deliverySlot,
          'p_delivery_instructions': order.deliveryInstructions,
          'p_items': itemsPayload,
          'p_idempotency_key':
              '${uid}_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final result = rpcRes as Map<String, dynamic>;
      final orderId = result['order_id'] as String;

      // Fetch the created authoritative order from database
      final fullOrder = await getOrderById(orderId);
      if (fullOrder != null) return fullOrder;

      return order.copyWith(id: orderId, orderNumber: result['order_number']);
    } catch (e) {
      debugPrint('Error creating order in Supabase: $e');
      rethrow;
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      final res = await _client
          .from('orders')
          .select('''
        *,
        branches (name),
        order_items (*),
        order_status_history (*)
      ''')
          .eq('id', orderId)
          .maybeSingle();

      if (res == null) return null;
      return _mapOrderFromJson(res);
    } catch (e) {
      debugPrint('Error fetching order $orderId: $e');
      return null;
    }
  }

  @override
  Future<Order> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    String? rejectionReason,
    DeliveryPartner? deliveryPartner,
  }) async {
    try {
      final notes =
          rejectionReason ??
          reason ??
          'Status changed to ${newStatus.rawValue}';
      final actorId = _client.auth.currentUser?.id;

      await _client.rpc(
        'transition_order_status',
        params: {
          'p_order_id': orderId,
          'p_new_status': newStatus.rawValue,
          'p_notes': notes,
          'p_actor_id': actorId,
        },
      );

      if (deliveryPartner != null) {
        await _client
            .from('orders')
            .update({'assigned_delivery_staff_id': deliveryPartner.id})
            .eq('id', orderId);
      }

      final updated = await getOrderById(orderId);
      if (updated != null) return updated;

      throw Exception('Failed to reload order after transition');
    } catch (e) {
      debugPrint('Error updating order status in Supabase: $e');
      rethrow;
    }
  }

  Future<void> assignDeliveryStaff(
    String orderId,
    String deliveryStaffId,
  ) async {
    try {
      await _client
          .from('orders')
          .update({'assigned_delivery_staff_id': deliveryStaffId})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Error assigning delivery staff: $e');
      rethrow;
    }
  }

  @override
  Future<Order> cancelOrder(
    String orderId, {
    String reason = 'Cancelled by customer',
  }) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled, reason: reason);
  }

  // --- Reports & Admin RPCs ---

  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    try {
      final res = await _client.rpc(
        'get_admin_sales_report',
        params: {
          'p_start_date':
              (startDate ?? DateTime.now().subtract(const Duration(days: 30)))
                  .toIso8601String(),
          'p_end_date': (endDate ?? DateTime.now()).toIso8601String(),
          'p_branch_id': branchId,
        },
      );

      if (res is List && res.isNotEmpty) {
        return res.first as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching sales report: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getBestsellingReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    int limit = 10,
  }) async {
    try {
      final res = await _client.rpc(
        'get_bestselling_products',
        params: {
          'p_start_date':
              (startDate ?? DateTime.now().subtract(const Duration(days: 30)))
                  .toIso8601String(),
          'p_end_date': (endDate ?? DateTime.now()).toIso8601String(),
          'p_branch_id': branchId,
          'p_limit': limit,
        },
      );

      return (res as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching bestsellers report: $e');
      return [];
    }
  }

  // Helper mapper
  Order _mapOrderFromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List? ?? [];
    final items = rawItems.map((item) {
      final dummyProduct = Product(
        id: item['product_id'] as String,
        name: item['product_name'] as String,
        localName: '',
        categoryId: '',
        unit: item['unit'] as String? ?? '1 kg',
        description: '',
        storageTips: '',
        origin: '',
        emoji: '🥗',
        basePricePaise: (item['price_paise'] as num).toInt(),
      );
      return CartItem(
        product: dummyProduct,
        quantity: (item['quantity'] as num).toInt(),
        branchId: json['branch_id'] as String? ?? '',
        unitPricePaise: (item['price_paise'] as num).toInt(),
      );
    }).toList();

    final rawTimeline = json['order_status_history'] as List? ?? [];
    final timeline =
        rawTimeline.map((evt) => OrderStatusEvent.fromJson(evt)).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Order.fromJson(
      json,
      itemsList: items,
      timelineList: timeline,
      deliveryPartner: json['assigned_delivery_staff_id'] != null
          ? DeliveryPartner(
              id: json['assigned_delivery_staff_id'] as String,
              name: 'Assigned Partner',
              phone: '+91 98450 12345',
              vehicleNumber: 'KA-01-ET-7890 (EV)',
              rating: 4.85,
            )
          : null,
    );
  }
}
