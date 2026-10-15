import 'package:flutter/material.dart';

import 'package:vegora_core/vegora_core.dart';

enum OrderStatus {
  newOrder,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
  rejected;

  static OrderStatus fromDb(String? raw) {
    if (raw == null) return OrderStatus.newOrder;
    switch (raw.toUpperCase()) {
      case 'NEW':
        return OrderStatus.newOrder;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'REJECTED':
        return OrderStatus.rejected;
      default:
        return OrderStatus.newOrder;
    }
  }
}

extension OrderStatusExtension on OrderStatus {
  String get rawValue {
    switch (this) {
      case OrderStatus.newOrder:
        return 'NEW';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatus.outForDelivery:
        return 'OUT_FOR_DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName => label;

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Accepted by Store';
      case OrderStatus.preparing:
        return 'Packing Fresh Veggies';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.newOrder:
        return 'Your order has been received by the branch store.';
      case OrderStatus.accepted:
        return 'Store manager reviewed and confirmed your items.';
      case OrderStatus.preparing:
        return 'Store team is hand-picking and grading fresh items.';
      case OrderStatus.readyForPickup:
        return 'Bagged and sealed. Waiting for delivery partner.';
      case OrderStatus.outForDelivery:
        return 'Delivery partner is on the way to your address.';
      case OrderStatus.delivered:
        return 'Delivered safely to your doorstep.';
      case OrderStatus.cancelled:
        return 'Order was cancelled by the customer.';
      case OrderStatus.rejected:
        return 'Store was unable to fulfill order.';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.newOrder:
        return AppColors.statusNew;
      case OrderStatus.accepted:
        return AppColors.statusAccepted;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.readyForPickup:
        return AppColors.statusReadyForPickup;
      case OrderStatus.outForDelivery:
        return AppColors.statusOutForDelivery;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.newOrder:
        return Icons.receipt_long_rounded;
      case OrderStatus.accepted:
        return Icons.thumb_up_alt_rounded;
      case OrderStatus.preparing:
        return Icons.shopping_basket_rounded;
      case OrderStatus.readyForPickup:
        return Icons.inventory_2_rounded;
      case OrderStatus.outForDelivery:
        return Icons.electric_moped_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
      case OrderStatus.rejected:
        return Icons.block_rounded;
    }
  }

  /// Whether the customer is allowed to cancel at this stage
  bool get canCustomerCancel {
    return this == OrderStatus.newOrder || this == OrderStatus.accepted;
  }

  /// Active non-terminal order
  bool get isTerminal {
    return this == OrderStatus.delivered ||
        this == OrderStatus.cancelled ||
        this == OrderStatus.rejected;
  }

  /// Milestone step (1-5) for timeline progress
  int get timelineStep {
    switch (this) {
      case OrderStatus.newOrder:
        return 1;
      case OrderStatus.accepted:
        return 2;
      case OrderStatus.preparing:
        return 3;
      case OrderStatus.readyForPickup:
        return 4;
      case OrderStatus.outForDelivery:
        return 5;
      case OrderStatus.delivered:
        return 6;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return -1;
    }
  }
}
