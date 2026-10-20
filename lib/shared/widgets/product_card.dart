import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vegora_core/localization/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/branch.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import 'branch_switch_dialog.dart';
import 'product_image_view.dart';
import 'quantity_selector_sheet.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBranch = ref.watch(selectedBranchProvider);
    final cart = ref.watch(cartProvider);
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';
    final l10n = context.l10n;

    final isAvailable = product.isAvailableAtBranch(currentBranch.id);
    final stock = product.getStockForBranch(currentBranch.id);
    final pricePaise = product.getPricePaiseForBranch(currentBranch.id);
    final qtyInCart = ref.read(cartProvider.notifier).getQuantity(product.id);

    final displayName = product.displayName(locale.languageCode);
    final secondaryName = isTamil
        ? (product.name)
        : (product.nameTa.isNotEmpty ? product.nameTa : product.localName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Produce Photography Container
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: ProductImageView(
                      imageUrl: product.imageUrl,
                      fallbackEmoji: product.emoji,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(10),
                      emojiSize: 44,
                    ),
                  ),

                  // Semantic Badges
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isOrganic)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  size: 10,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  l10n.organic,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (product.isBestSeller)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              l10n.bestSeller,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Out of stock overlay
                  if (!isAvailable || stock == 0)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neutral700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.outOfStock.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Product Primary Name
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: isTamil ? 1.35 : 1.2,
                letterSpacing: -0.2,
              ),
            ),

            // Secondary Name / Local Name
            Text(
              secondaryName.isNotEmpty ? secondaryName : product.origin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),

            // Unit/weight label (e.g. per kg / ஒரு கிலோ)
            Text(
              product.formatUnitLabel(isTamil: isTamil),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Price & Add to Cart Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.formatPaise(pricePaise),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (product.originalPricePaise != null &&
                        product.originalPricePaise! > pricePaise)
                      Text(
                        CurrencyFormatter.formatPaise(
                          product.originalPricePaise!,
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),

                // Quick-Commerce Add / Stepper Button
                if (!isAvailable || stock == 0)
                  const SizedBox.shrink()
                else if (qtyInCart == 0)
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          _handleAddToCart(context, ref, currentBranch, cart),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.add.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.add, size: 14),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => QuantitySelectorSheet.show(
                      context,
                      product: product,
                      initialQuantity: qtyInCart,
                    ),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => ref
                                .read(cartProvider.notifier)
                                .decrementQuantity(product.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.remove,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              product.formatQuantity(
                                qtyInCart,
                                isTamil: isTamil,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final currentStock = product.getStockForBranch(
                                currentBranch.id,
                              );
                              final step = product.quantityStep;
                              if (qtyInCart + step <= currentStock) {
                                ref
                                    .read(cartProvider.notifier)
                                    .incrementQuantity(product.id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isTamil
                                          ? 'அதிகபட்ச இருப்பு அளவு எட்டப்பட்டது'
                                          : 'Maximum available stock reached',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.add,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    Branch currentBranch,
    Cart cart,
  ) async {
    final qty = product.isWeightBased ? product.minOrderQuantity : 1;
    if (product.allowCustomQuantity && product.isWeightBased) {
      if (!context.mounted) return;
      QuantitySelectorSheet.show(context, product: product);
      return;
    }

    try {
      ref
          .read(cartProvider.notifier)
          .addItem(product, currentBranch.id, quantity: qty);
      final isTamil = ref.read(appLocaleProvider).languageCode == 'ta';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTamil
                ? '${product.displayName("ta")} கூடையில் சேர்க்கப்பட்டது!'
                : '${product.name} added to cart!',
          ),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: isTamil ? 'கூடை' : 'Cart',
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
              .switchBranchAndClear(
                currentBranch.id,
                initialProduct: product,
                initialQuantity: qty,
              );
        },
      );
    }
  }
}
