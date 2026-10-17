import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/product.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/branch_switch_dialog.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/product_image_view.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogRepo = ref.watch(catalogRepositoryProvider);
    final currentBranch = ref.watch(selectedBranchProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vegetable Details'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cart.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.totalItemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: catalogRepo.getProductById(productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data!;
          final isAvailable = product.isAvailableAtBranch(currentBranch.id);
          final stock = product.getStockForBranch(currentBranch.id);
          final pricePaise = product.getPricePaiseForBranch(currentBranch.id);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Showcase
                Container(
                  width: double.infinity,
                  height: 240,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: Hero(
                    tag: 'product_${product.id}',
                    child: ProductImageView(
                      imageUrl: product.imageUrl,
                      fallbackEmoji: product.emoji,
                      fit: BoxFit.contain,
                      emojiSize: 96,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(
                        children: [
                          if (product.isOrganic) ...[
                            _buildPill('100% ORGANIC', AppColors.primary),
                            const SizedBox(width: 8),
                          ],
                          if (product.isBestSeller) ...[
                            _buildPill('BEST SELLER', AppColors.secondary),
                            const SizedBox(width: 8),
                          ],
                          _buildPill(
                            isAvailable ? 'IN STOCK: $stock' : 'OUT OF STOCK',
                            isAvailable
                                ? AppColors.primaryDark
                                : AppColors.statusCancelled,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Name & Local Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.localName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Price and Unit
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatPaise(pricePaise),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.originalPricePaise != null &&
                              product.originalPricePaise! > pricePaise) ...[
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatPaise(
                                product.originalPricePaise!,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            'per ${product.unit}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Branch specific fulfillment badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.store_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fulfilling from ${currentBranch.name}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? '$stock units available in-store'
                                        : 'Currently unavailable at this branch',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isAvailable
                                          ? AppColors.textSecondary
                                          : AppColors.statusCancelled,
                                      fontWeight: isAvailable
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'About This Produce',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Storage & Origin Specs
                      _buildSpecRow(
                        Icons.kitchen_rounded,
                        'Storage Tips',
                        product.storageTips,
                      ),
                      const SizedBox(height: 10),
                      _buildSpecRow(
                        Icons.agriculture_rounded,
                        'Farm Origin',
                        product.origin,
                      ),

                      const SizedBox(height: 28),

                      // Related Vegetables in same category
                      const Text(
                        'You May Also Like',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Product>>(
                        future: catalogRepo.getProducts(
                          categoryId: product.categoryId,
                        ),
                        builder: (context, relSnapshot) {
                          if (!relSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final related = relSnapshot.data!
                              .where((p) => p.id != product.id)
                              .take(4)
                              .toList();

                          if (related.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: 230,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: related.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 160,
                                  child: ProductCard(
                                    product: related[index],
                                    onTap: () {
                                      context.push(
                                        '/product/${related[index].id}',
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 80,
                      ), // Padding for bottom sticky bar
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Bottom Add to Cart Bar
      bottomNavigationBar: FutureBuilder<Product?>(
        future: catalogRepo.getProductById(productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final product = snapshot.data!;
          final isAvailable = product.isAvailableAtBranch(currentBranch.id);
          final stock = product.getStockForBranch(currentBranch.id);
          final qtyInCart = ref
              .watch(cartProvider.notifier)
              .getQuantity(product.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (qtyInCart > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(product.id, qtyInCart - 1);
                            },
                          ),
                          Text(
                            '$qtyInCart in cart',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              if (qtyInCart < stock) {
                                ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(product.id, qtyInCart + 1);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Only $stock in stock'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable
                              ? AppColors.primary
                              : AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: !isAvailable || stock == 0
                            ? null
                            : () => _handleAddToCart(
                                context,
                                ref,
                                product,
                                currentBranch,
                                cart,
                              ),
                        child: Text(
                          !isAvailable || stock == 0
                              ? 'Out of Stock'
                              : qtyInCart > 0
                              ? 'View Shopping Cart'
                              : 'Add to Cart',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    Product product,
    currentBranch,
    cart,
  ) {
    if (ref.read(cartProvider.notifier).getQuantity(product.id) > 0) {
      context.go('/cart');
      return;
    }

    try {
      ref.read(cartProvider.notifier).addItem(product, currentBranch.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart!'),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    } on BranchMismatchException catch (e) {
      final branches = ref.read(branchesListProvider).value ?? [];
      final oldBranch = branches.firstWhere(
        (b) => b.id == e.currentBranchId,
        orElse: () => currentBranch,
      );

      BranchSwitchDialog.show(
        context: context,
        currentBranch: oldBranch,
        newBranch: currentBranch,
        pendingProduct: product,
        onConfirm: () {
          ref
              .read(cartProvider.notifier)
              .switchBranchAndClear(currentBranch.id, initialProduct: product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Switched to ${currentBranch.name}. Cart refreshed.',
              ),
            ),
          );
        },
      );
    }
  }
}
