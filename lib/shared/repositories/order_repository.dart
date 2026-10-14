import '../models/cart_item.dart';
import '../models/delivery_partner.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'branch_repository.dart';
import 'catalog_repository.dart';

abstract class OrderRepository {
  Future<List<Order>> getAllOrders();
  Future<List<Order>> getCustomerOrders(String customerPhone);
  Future<List<Order>> getBranchOrders(String branchId);
  Future<List<Order>> getDeliveryOrders(String deliveryPartnerId);
  Future<Order> createOrder(Order order);
  Future<Order> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    String? rejectionReason,
    DeliveryPartner? deliveryPartner,
  });
  Future<Order> cancelOrder(
    String orderId, {
    String reason = 'Cancelled by customer',
  });
}

class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];

  static const DeliveryPartner sampleDeliveryPartner = DeliveryPartner(
    id: 'dp_ramesh_01',
    name: 'Ramesh Kumar',
    phone: '+91 98450 12345',
    vehicleNumber: 'KA-01-ET-7890 (EV Scooter)',
    rating: 4.85,
    totalDeliveriesCompleted: 142,
  );

  MockOrderRepository() {
    _seedInitialOrders();
  }

  void _seedInitialOrders() {
    final now = DateTime.now();

    final branch1 = MockBranchRepository.sampleBranches[0]; // Indiranagar
    final branch2 = MockBranchRepository.sampleBranches[1]; // Koramangala
    final address1 = MockBranchRepository.sampleAddresses[0];
    final address2 = MockBranchRepository.sampleAddresses[1];

    final pTomato = MockCatalogRepository.sampleProducts[0];
    final pSpinach = MockCatalogRepository.sampleProducts[6];
    final pBanana = MockCatalogRepository.sampleProducts[18];
    final pOnion = MockCatalogRepository.sampleProducts[14];
    final pCarrot = MockCatalogRepository.sampleProducts[11];

    // Order 1: NEW incoming order (Ready for Branch Staff to accept/reject)
    _orders.add(
      Order(
        id: 'ord_1001',
        orderNumber: '#OD-9821',
        customerId: 'cust_01',
        customerName: 'Ananya Sharma',
        customerPhone: '9876543210',
        deliveryAddress: address1,
        branchId: branch1.id,
        branchName: branch1.name,
        items: [
          CartItem(
            product: pTomato,
            quantity: 2,
            branchId: branch1.id,
            unitPricePaise: pTomato.getPricePaiseForBranch(branch1.id),
          ),
          CartItem(
            product: pSpinach,
            quantity: 1,
            branchId: branch1.id,
            unitPricePaise: pSpinach.getPricePaiseForBranch(branch1.id),
          ),
        ],
        subtotalPaise: 8600, // (32*2 + 22) = ₹86
        deliveryFeePaise: 2900, // ₹29
        discountPaise: 0,
        totalPaise: 11500, // ₹115
        status: OrderStatus.newOrder,
        paymentMethod: 'Cash on Delivery',
        deliverySlot: 'Today, 5:00 PM - 7:00 PM',
        deliveryInstructions:
            'Leave with security guard if not answering bell.',
        createdAt: now.subtract(const Duration(minutes: 10)),
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.newOrder,
            timestamp: now.subtract(const Duration(minutes: 10)),
            note: 'Order submitted online by customer',
          ),
        ],
        assignedDeliveryPartner: sampleDeliveryPartner,
      ),
    );

    // Order 2: PREPARING (Store packing items)
    _orders.add(
      Order(
        id: 'ord_1002',
        orderNumber: '#OD-9820',
        customerId: 'cust_01',
        customerName: 'Ananya Sharma',
        customerPhone: '9876543210',
        deliveryAddress: address1,
        branchId: branch1.id,
        branchName: branch1.name,
        items: [
          CartItem(
            product: pOnion,
            quantity: 2,
            branchId: branch1.id,
            unitPricePaise: pOnion.getPricePaiseForBranch(branch1.id),
          ),
          CartItem(
            product: pCarrot,
            quantity: 1,
            branchId: branch1.id,
            unitPricePaise: pCarrot.getPricePaiseForBranch(branch1.id),
          ),
          CartItem(
            product: pBanana,
            quantity: 1,
            branchId: branch1.id,
            unitPricePaise: pBanana.getPricePaiseForBranch(branch1.id),
          ),
        ],
        subtotalPaise: 13400,
        deliveryFeePaise: 2900,
        discountPaise: 0,
        totalPaise: 16300,
        status: OrderStatus.preparing,
        paymentMethod: 'Simulated UPI',
        deliverySlot: 'Today, 2:00 PM - 4:00 PM',
        deliveryInstructions: 'Please ring bell twice.',
        createdAt: now.subtract(const Duration(minutes: 45)),
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.newOrder,
            timestamp: now.subtract(const Duration(minutes: 45)),
            note: 'Order placed by customer',
          ),
          OrderStatusEvent(
            status: OrderStatus.accepted,
            timestamp: now.subtract(const Duration(minutes: 38)),
            note: 'Branch store accepted the order',
          ),
          OrderStatusEvent(
            status: OrderStatus.preparing,
            timestamp: now.subtract(const Duration(minutes: 25)),
            note: 'Staff started sorting and bagging fresh produce',
          ),
        ],
        assignedDeliveryPartner: sampleDeliveryPartner,
      ),
    );

    // Order 3: READY_FOR_PICKUP (Ready for Delivery Staff to pick up)
    _orders.add(
      Order(
        id: 'ord_1003',
        orderNumber: '#OD-9818',
        customerId: 'cust_02',
        customerName: 'Vikram Joshi',
        customerPhone: '9844012345',
        deliveryAddress: address2,
        branchId: branch2.id,
        branchName: branch2.name,
        items: [
          CartItem(
            product: pBanana,
            quantity: 2,
            branchId: branch2.id,
            unitPricePaise: pBanana.getPricePaiseForBranch(branch2.id),
          ),
        ],
        subtotalPaise: 6000,
        deliveryFeePaise: 2500,
        discountPaise: 0,
        totalPaise: 8500,
        status: OrderStatus.readyForPickup,
        paymentMethod: 'Simulated UPI',
        deliverySlot: 'Today, 1:00 PM - 3:00 PM',
        deliveryInstructions: 'Call upon arrival at tower gate.',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.newOrder,
            timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
            note: 'Order placed',
          ),
          OrderStatusEvent(
            status: OrderStatus.accepted,
            timestamp: now.subtract(const Duration(hours: 1)),
            note: 'Confirmed by Koramangala store',
          ),
          OrderStatusEvent(
            status: OrderStatus.preparing,
            timestamp: now.subtract(const Duration(minutes: 50)),
            note: 'Fresh items packed and sanitized',
          ),
          OrderStatusEvent(
            status: OrderStatus.readyForPickup,
            timestamp: now.subtract(const Duration(minutes: 20)),
            note: 'Order crate staged at dispatch counter',
          ),
        ],
        assignedDeliveryPartner: sampleDeliveryPartner,
      ),
    );

    // Order 4: DELIVERED (Past completed order)
    _orders.add(
      Order(
        id: 'ord_1000',
        orderNumber: '#OD-9750',
        customerId: 'cust_01',
        customerName: 'Ananya Sharma',
        customerPhone: '9876543210',
        deliveryAddress: address1,
        branchId: branch1.id,
        branchName: branch1.name,
        items: [
          CartItem(
            product: pTomato,
            quantity: 1,
            branchId: branch1.id,
            unitPricePaise: 3200,
          ),
        ],
        subtotalPaise: 3200,
        deliveryFeePaise: 2900,
        discountPaise: 0,
        totalPaise: 6100,
        status: OrderStatus.delivered,
        paymentMethod: 'Cash on Delivery',
        deliverySlot: 'Yesterday Morning',
        deliveryInstructions: 'Delivered',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.newOrder,
            timestamp: now.subtract(const Duration(days: 1, hours: 4)),
            note: 'Order placed',
          ),
          OrderStatusEvent(
            status: OrderStatus.delivered,
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            note: 'Delivered to customer',
          ),
        ],
        assignedDeliveryPartner: sampleDeliveryPartner,
      ),
    );
  }

  @override
  Future<List<Order>> getAllOrders() async {
    return List.unmodifiable(_orders);
  }

  @override
  Future<List<Order>> getCustomerOrders(String customerPhone) async {
    return _orders.where((o) => o.customerPhone == customerPhone).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Order>> getBranchOrders(String branchId) async {
    return _orders.where((o) => o.branchId == branchId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Order>> getDeliveryOrders(String deliveryPartnerId) async {
    return _orders.where((o) {
      return o.assignedDeliveryPartner?.id == deliveryPartnerId;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Order> createOrder(Order order) async {
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<Order> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    String? rejectionReason,
    DeliveryPartner? deliveryPartner,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw Exception('Order not found: $orderId');
    }

    final effectiveReason = rejectionReason ?? reason;
    final current = _orders[index];
    final updatedTimeline = List<OrderStatusEvent>.from(current.statusTimeline)
      ..add(
        OrderStatusEvent(
          status: newStatus,
          timestamp: DateTime.now(),
          note: effectiveReason ?? newStatus.description,
        ),
      );

    final updated = current.copyWith(
      status: newStatus,
      rejectionReason: effectiveReason ?? current.rejectionReason,
      statusTimeline: updatedTimeline,
      assignedDeliveryPartner:
          deliveryPartner ?? current.assignedDeliveryPartner,
    );

    _orders[index] = updated;
    return updated;
  }

  @override
  Future<Order> cancelOrder(
    String orderId, {
    String reason = 'Cancelled by customer',
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw Exception('Order not found: $orderId');
    }

    final current = _orders[index];
    if (!current.canBeCancelled) {
      throw Exception(
        'Order cannot be cancelled in status ${current.status.label}',
      );
    }

    return updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
      rejectionReason: reason,
    );
  }
}
