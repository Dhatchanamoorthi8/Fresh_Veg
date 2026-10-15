import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_models/vegora_models.dart';

class BranchMismatchException implements Exception {
  final String currentBranchId;
  final String newBranchId;
  final Product pendingProduct;

  BranchMismatchException({
    required this.currentBranchId,
    required this.newBranchId,
    required this.pendingProduct,
  });

  @override
  String toString() =>
      'Cart already contains items from branch $currentBranchId. Cannot add from $newBranchId without clearing cart.';
}

class OutOfStockException implements Exception {
  final String message;
  OutOfStockException(this.message);

  @override
  String toString() => message;
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    return const Cart();
  }

  /// Adds a product to the cart.
  /// Throws [BranchMismatchException] if the cart has items from another branch.
  /// Throws [OutOfStockException] if the item is out of stock.
  void addItem(Product product, String branchId, {int quantity = 1}) {
    if (!product.isAvailableAtBranch(branchId)) {
      throw OutOfStockException(
        '${product.name} is currently out of stock at this branch.',
      );
    }

    final maxStock = product.getStockForBranch(branchId);
    if (state.isNotEmpty &&
        state.branchId != null &&
        state.branchId != branchId) {
      throw BranchMismatchException(
        currentBranchId: state.branchId!,
        newBranchId: branchId,
        pendingProduct: product,
      );
    }

    final existingIndex = state.items.indexWhere(
      (i) => i.product.id == product.id,
    );
    final unitPrice = product.getPricePaiseForBranch(branchId);

    if (existingIndex >= 0) {
      final currentItem = state.items[existingIndex];
      final newQty = currentItem.quantity + quantity;
      if (newQty > maxStock) {
        throw OutOfStockException(
          'Only $maxStock units available in this branch.',
        );
      }

      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = currentItem.copyWith(
        quantity: newQty,
        unitPricePaise: unitPrice,
      );
      state = state.copyWith(items: updatedItems, branchId: branchId);
    } else {
      if (quantity > maxStock) {
        throw OutOfStockException(
          'Only $maxStock units available in this branch.',
        );
      }

      final newItem = CartItem(
        product: product,
        quantity: quantity,
        branchId: branchId,
        unitPricePaise: unitPrice,
      );
      state = state.copyWith(
        branchId: branchId,
        items: [...state.items, newItem],
      );
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;

    final currentItem = state.items[index];
    final branchId = state.branchId ?? currentItem.branchId;
    final maxStock = currentItem.product.getStockForBranch(branchId);

    if (newQuantity > maxStock) {
      throw OutOfStockException('Only $maxStock units available in stock.');
    }

    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[index] = currentItem.copyWith(quantity: newQuantity);
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems = state.items
        .where((i) => i.product.id != productId)
        .toList();
    if (updatedItems.isEmpty) {
      state = const Cart(); // Reset branchId when empty
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  void clearCart() {
    state = const Cart();
  }

  /// Explicitly reset cart and switch to new branch (e.g. after customer confirms)
  void switchBranchAndClear(String newBranchId, {Product? initialProduct}) {
    if (initialProduct != null) {
      final unitPrice = initialProduct.getPricePaiseForBranch(newBranchId);
      state = Cart(
        branchId: newBranchId,
        items: [
          CartItem(
            product: initialProduct,
            quantity: 1,
            branchId: newBranchId,
            unitPricePaise: unitPrice,
          ),
        ],
      );
    } else {
      state = Cart(branchId: newBranchId, items: const []);
    }
  }

  int getQuantity(String productId) {
    for (final item in state.items) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }
    return 0;
  }
}
