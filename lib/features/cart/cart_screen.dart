import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
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
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(isTamil ? 'கூடை' : 'Shopping Cart')),
        body: EmptyStateView(
          emoji: '🛒',
          title: isTamil ? 'உங்கள் கூடை காலியாக உள்ளது' : 'Your Cart is Empty',
          message: isTamil
              ? 'புதிய காய்கறிகள், கீரைகள் உங்கள் வருகைக்காக காத்திருக்கின்றன!'
              : 'Fresh leafy greens, tomatoes, and crunchy veggies are waiting for you!',
          buttonText: isTamil
              ? 'காய்கறிகளை வாங்குங்கள்'
              : 'Shop Fresh Vegetables',
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
        title: Text(isTamil ? 'கூடை' : 'Shopping Cart'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTamil ? 'கூடை நீக்கப்பட்டது' : 'Cart cleared',
                  ),
                ),
              );
            },
            child: Text(
              isTamil ? 'அனைத்தும் நீக்கு' : 'Clear All',
              style: const TextStyle(color: AppColors.statusCancelled),
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
                      isTamil
                          ? 'கிளை: ${currentBranch.name} (~${currentBranch.estimatedDeliveryMinutes} நிமி)'
                          : 'Fulfilling from: ${currentBranch.name} (~${currentBranch.estimatedDeliveryMinutes}m)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/branches'),
                    child: Text(
                      isTamil ? 'மாற்று' : 'Change',
                      style: const TextStyle(
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
                          ? (isTamil
                                ? '🎉 இக்கிளையிலிருந்து இலவச டெலிவரி கிடைத்துள்ளது!'
                                : '🎉 You unlocked FREE Delivery from this branch!')
                          : (isTamil
                                ? 'இன்னும் ${CurrencyFormatter.formatPaise(remainingForFreeDelivery)} சேர்த்தால் இலவச டெலிவரி!'
                                : 'Add ${CurrencyFormatter.formatPaise(remainingForFreeDelivery)} more to get FREE Delivery!'),
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
                                product.displayName(locale.languageCode),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: isTamil ? 1.35 : 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.formatPaise(item.unitPricePaise)} / ${product.formatUnitLabel(isTamil: isTamil)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: isTamil ? 1.3 : 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${isTamil ? "மொத்தம்" : "Item Total"}: ${CurrencyFormatter.formatPaise(item.totalPaise)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity Stepper (Weight/Gram Aware)
                        Container(
                          height: 36,
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
                                      .decrementQuantity(product.id);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  item.formattedQuantity(isTamil: isTamil),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  final step = product.isWeightBased
                                      ? product.quantityStep
                                      : 1;
                                  if (item.quantity + step <= stock) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .incrementQuantity(product.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isTamil
                                              ? 'அதிகபட்ச இருப்பு ${product.formatQuantity(stock, isTamil: true)} மட்டுமே'
                                              : 'Maximum available stock is ${product.formatQuantity(stock)}',
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
                  hintText: isTamil
                      ? 'டெலிவரி குறிப்புகள் (எ.கா. காவலாளியிடம் கொடுக்கவும்)...'
                      : 'Delivery instructions (e.g. Leave with guard, ring bell)...',
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
                  Text(
                    isTamil ? 'கட்டண விவரங்கள்' : 'Bill Details',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBillRow(
                    isTamil ? 'பொருட்களின் கட்டணம்' : 'Item Subtotal',
                    CurrencyFormatter.formatPaise(subtotal),
                  ),
                  const SizedBox(height: 8),
                  _buildBillRow(
                    isTamil ? 'டெலிவரி கட்டணம்' : 'Delivery Partner Fee',
                    deliveryFee == 0
                        ? (isTamil ? 'இலவசம்' : 'FREE')
                        : CurrencyFormatter.formatPaise(deliveryFee),
                    isGreen: deliveryFee == 0,
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildBillRow(
                      isTamil ? 'தள்ளுபடி' : 'Promotional Discount',
                      '-${CurrencyFormatter.formatPaise(discount)}',
                      isGreen: true,
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTamil ? 'செலுத்த வேண்டிய தொகை' : 'To Pay',
                        style: const TextStyle(
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

            const SizedBox(height: 100),
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
                    isTamil
                        ? '${currentBranch.name} கிளைக்கான குறைந்தபட்ச ஆர்டர் தொகை ${CurrencyFormatter.formatPaise(currentBranch.minOrderAmountPaise)}'
                        : 'Minimum order amount for ${currentBranch.name} is ${CurrencyFormatter.formatPaise(currentBranch.minOrderAmountPaise)}',
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
                      Text(
                        isTamil ? 'மொத்த தொகை' : 'TOTAL AMOUNT',
                        style: const TextStyle(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isTamil
                                  ? 'செக் அவுட் செய்க'
                                  : 'Proceed to Checkout',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
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
