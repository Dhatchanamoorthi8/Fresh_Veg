import 'branch.dart';
import 'cart_item.dart';

class Cart {
  final String? branchId;
  final List<CartItem> items;

  const Cart({this.branchId, this.items = const []});

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Counts the distinct items / packs in cart for badges
  int get totalItemCount => items.fold(0, (sum, item) => sum + (item.product.isWeightBased ? 1 : item.quantity));
  int get uniqueProductCount => items.length;

  int get subtotalPaise => items.fold(0, (sum, item) => sum + item.totalPaise);

  /// Promotional savings or discount (5% discount if subtotal exceeds ₹500)
  int get discountPaise {
    if (subtotalPaise >= 50000) {
      return (subtotalPaise * 0.05).round();
    }
    return 0;
  }

  /// Calculates delivery fee based on branch threshold
  int deliveryFeePaise(Branch? branch) {
    if (isEmpty) return 0;
    final threshold = branch?.freeDeliveryThresholdPaise ?? 24900;
    final fee = branch?.standardDeliveryFeePaise ?? 2900;

    if (subtotalPaise >= threshold) {
      return 0; // Free delivery
    }
    return fee;
  }

  int totalPaise(Branch? branch) {
    if (isEmpty) return 0;
    final total = subtotalPaise - discountPaise + deliveryFeePaise(branch);
    return total > 0 ? total : 0;
  }

  bool isEligibleForFreeDelivery(Branch? branch) {
    final threshold = branch?.freeDeliveryThresholdPaise ?? 24900;
    return subtotalPaise >= threshold;
  }

  int remainingForFreeDeliveryPaise(Branch? branch) {
    final threshold = branch?.freeDeliveryThresholdPaise ?? 24900;
    final diff = threshold - subtotalPaise;
    return diff > 0 ? diff : 0;
  }

  bool meetsMinimumOrder(Branch? branch) {
    final minAmount = branch?.minOrderAmountPaise ?? 9900;
    return subtotalPaise >= minAmount;
  }

  Cart copyWith({String? branchId, List<CartItem>? items}) {
    return Cart(
      branchId: branchId ?? this.branchId,
      items: items ?? this.items,
    );
  }
}
