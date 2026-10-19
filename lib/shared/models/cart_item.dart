import 'product.dart';

class CartItem {
  final Product product;

  /// Quantity in canonical integer grams (for weight products) or piece count (for piece/bunch products).
  final int quantity;
  final String branchId;

  /// Selling price in paise (per kg for weight products, or per piece/bunch for count products).
  final int unitPricePaise;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.branchId,
    required this.unitPricePaise,
  });

  /// Authoritative line total calculation in paise:
  /// Weight products: (unitPricePaisePerKg * quantityGrams) / 1000
  /// Count products:  unitPricePaisePerPiece * quantity
  int get totalPaise => product.calculatePricePaise(quantity, unitPricePaise);

  /// Convenient alias for totalPaise
  int get lineTotalPaise => totalPaise;

  /// Human-readable quantity string (e.g. "500 g", "1.5 kg", "2 pcs" or Tamil equivalents)
  String formattedQuantity({bool isTamil = false}) =>
      product.formatQuantity(quantity, isTamil: isTamil);

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
