import 'cart_item.dart';
import 'customer_address.dart';
import 'delivery_partner.dart';
import 'order_status.dart';

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;
  final String note;

  const OrderStatusEvent({
    required this.status,
    required this.timestamp,
    required this.note,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: OrderStatus.fromDb(json['status'] as String?),
      timestamp:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      note: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.rawValue,
      'created_at': timestamp.toIso8601String(),
      'notes': note,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final CustomerAddress deliveryAddress;
  final String branchId;
  final String branchName;
  final List<CartItem> items;
  final int subtotalPaise;
  final int deliveryFeePaise;
  final int discountPaise;
  final int totalPaise;
  final OrderStatus status;
  final String? rejectionReason;
  final String paymentMethod;
  final String deliverySlot;
  final String deliveryInstructions;
  final DateTime createdAt;
  final List<OrderStatusEvent> statusTimeline;
  final DeliveryPartner? assignedDeliveryPartner;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.branchId,
    required this.branchName,
    required this.items,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.discountPaise,
    required this.totalPaise,
    required this.status,
    this.rejectionReason,
    required this.paymentMethod,
    required this.deliverySlot,
    required this.deliveryInstructions,
    required this.createdAt,
    required this.statusTimeline,
    this.assignedDeliveryPartner,
  });

  String get deliveryAddressText =>
      '${deliveryAddress.fullAddress}, ${deliveryAddress.area} (${deliveryAddress.pinCode})';

  factory Order.fromJson(
    Map<String, dynamic> json, {
    List<CartItem>? itemsList,
    List<OrderStatusEvent>? timelineList,
    DeliveryPartner? deliveryPartner,
  }) {
    CustomerAddress addr;
    if (json['customer_addresses'] != null &&
        json['customer_addresses'] is Map<String, dynamic>) {
      addr = CustomerAddress.fromJson(
        json['customer_addresses'] as Map<String, dynamic>,
      );
    } else {
      addr = CustomerAddress(
        id: json['delivery_address_id'] as String? ?? '',
        label: 'Delivery Address',
        fullAddress: json['delivery_address_text'] as String? ?? '',
        area: '',
        landmark: '',
        pinCode: '',
        eligibleBranchId: json['branch_id'] as String? ?? '',
      );
    }

    final branchName =
        json['branches']?['name'] as String? ??
        (json['branch_name'] as String? ?? 'Store Branch');

    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? json['id'].toString(),
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryAddress: addr,
      branchId: json['branch_id'] as String? ?? '',
      branchName: branchName,
      items: itemsList ?? const [],
      subtotalPaise: (json['subtotal_paise'] as num?)?.toInt() ?? 0,
      deliveryFeePaise: (json['delivery_fee_paise'] as num?)?.toInt() ?? 0,
      discountPaise: (json['discount_paise'] as num?)?.toInt() ?? 0,
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromDb(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'Cash on Delivery',
      deliverySlot: json['delivery_slot'] as String? ?? 'Standard Delivery',
      deliveryInstructions: json['delivery_instructions'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      statusTimeline: timelineList ?? const [],
      assignedDeliveryPartner: deliveryPartner,
    );
  }

  bool get canBeCancelled => status.canCustomerCancel;

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    CustomerAddress? deliveryAddress,
    String? branchId,
    String? branchName,
    List<CartItem>? items,
    int? subtotalPaise,
    int? deliveryFeePaise,
    int? discountPaise,
    int? totalPaise,
    OrderStatus? status,
    String? rejectionReason,
    String? paymentMethod,
    String? deliverySlot,
    String? deliveryInstructions,
    DateTime? createdAt,
    List<OrderStatusEvent>? statusTimeline,
    DeliveryPartner? assignedDeliveryPartner,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      items: items ?? this.items,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      deliveryFeePaise: deliveryFeePaise ?? this.deliveryFeePaise,
      discountPaise: discountPaise ?? this.discountPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      createdAt: createdAt ?? this.createdAt,
      statusTimeline: statusTimeline ?? this.statusTimeline,
      assignedDeliveryPartner:
          assignedDeliveryPartner ?? this.assignedDeliveryPartner,
    );
  }
}
