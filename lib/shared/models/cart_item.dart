import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final String branchId;
  final int unitPricePaise;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.branchId,
    required this.unitPricePaise,
  });

  int get totalPaise => unitPricePaise * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? branchId,
    int? unitPricePaise,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      branchId: branchId ?? this.branchId,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product.id == other.product.id &&
          branchId == other.branchId;

  @override
  int get hashCode => product.id.hashCode ^ branchId.hashCode;
}
