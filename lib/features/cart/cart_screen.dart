import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/product_image_view.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currentBranch = ref.watch(selectedBranchProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: EmptyStateView(
          emoji: '🛒',
          title: 'Your Cart is Empty',
          message: 'Fresh leafy greens, tomatoes, and crunchy veggies are waiting for you!',
          buttonText: 'Shop Fresh Vegetables',
          onButtonPressed: () => context.go('/home'),
        ),
      );
    }

    final subtotal = cart.subtotalPaise;
    final deliveryFee = cart.deliveryFeePaise(currentBranch);
    final discount = cart.discountPaise;
    final total = cart.totalPaise(currentBranch);
    final isFreeDelivery = cart.isEligibleForFreeDelivery(currentBranch);
    final remainingForFreeDelivery = cart.remainingForFreeDeliveryPaise(
      currentBranch,
    );
    final meetsMinOrder = cart.meetsMinimumOrder(currentBranch);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cart cleared')));
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.statusCancelled),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Branch fulfillment info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fulfilling from: ${currentBranch.name} (~${currentBranch.estimatedDeliveryMinutes}m)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/branches'),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Free Delivery Progress Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFreeDelivery
                    ? AppColors.primaryContainer
                    : AppColors.secondaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFreeDelivery
                      ? AppColors.primaryLight
                      : AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isFreeDelivery
                        ? Icons.check_circle_rounded
                        : Icons.local_shipping_rounded,
                    color: isFreeDelivery
                        ? AppColors.primary
                        : AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isFreeDelivery
                          ? '🎉 You unlocked FREE Delivery from this branch!'
                          : 'Add ${CurrencyFormatter.formatPaise(remainingForFreeDelivery)} more to get FREE Delivery!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isFreeDelivery
                            ? AppColors.onPrimaryContainer
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cart Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  final product = item.product;
                  final stock = product.getStockForBranch(currentBranch.id);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Image Thumbnail
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: ProductImageView(
                            imageUrl: product.imageUrl,
                            fallbackEmoji: product.emoji,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(10),
                            emojiSize: 28,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Unit Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.formatPaise(item.unitPricePaise)} / ${product.unit}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Item Total: ${CurrencyFormatter.formatPaise(item.totalPaise)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity Stepper
                        Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                        product.id,
                                        item.quantity - 1,
                                      );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  if (item.quantity < stock) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          product.id,
                                          item.quantity + 1,
                                        );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Maximum available stock is $stock units',
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Instructions Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  hintText: 'Delivery instructions (e.g. Leave with guard, ring bell)...',
                  prefixIcon: const Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.textSecondary,
                  ),
                  fillColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bill Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBillRow(
                    'Item Subtotal',
                    CurrencyFormatter.formatPaise(subtotal),
                  ),
                  const SizedBox(height: 8),
                  _buildBillRow(
                    'Delivery Partner Fee',
                    deliveryFee == 0
                        ? 'FREE'
                        : CurrencyFormatter.formatPaise(deliveryFee),
                    isGreen: deliveryFee == 0,
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildBillRow(
                      'Promotional Discount',
                      '-${CurrencyFormatter.formatPaise(discount)}',
                      isGreen: true,
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'To Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Spacing for bottom action
          ],
        ),
      ),

      // Bottom Checkout Bar
      bottomNavigationBar: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!meetsMinOrder) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statusCancelled.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Minimum order amount for ${currentBranch.name} is ${CurrencyFormatter.formatPaise(currentBranch.minOrderAmountPaise)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.statusCancelled,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: meetsMinOrder
                              ? AppColors.primary
                              : AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: meetsMinOrder
                            ? () {
                                context.push(
                                  '/checkout',
                                  extra: _instructionsController.text.trim(),
                                );
                              }
                            : null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isGreen ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
