import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vegora_core/localization/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/branch.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'vegora_toast.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import 'branch_switch_dialog.dart';
import 'product_image_view.dart';
import 'quantity_selector_sheet.dart';

/// Production-grade quick-commerce product card with high-performance rasterization,
/// micro-scale tap feedback, concentric radii, content split divider, and animated stepper.
class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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

    final hasDiscount = product.originalPricePaise != null &&
        product.originalPricePaise! > pricePaise;
    final discountPercent = hasDiscount
        ? (((product.originalPricePaise! - pricePaise) /
                    product.originalPricePaise!) *
                100)
            .round()
        : 0;

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE6EAE7),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color(0x051F3A24),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP ZONE: PRODUCE IMAGE STAGE ---
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: ProductImageView(
                              imageUrl: product.imageUrl,
                              fallbackEmoji: product.emoji,
                              productName: product.name,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                              emojiSize: 42,
                            ),
                          ),

                          // Badges (Top Left: Organic / Bestseller)
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
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFC8E6C9),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.eco_rounded,
                                          size: 10,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          l10n.organic,
                                          style: AppTypography.badge(
                                            color: const Color(0xFF2E7D32),
                                            isTamil: isTamil,
                                          ).copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (product.isBestSeller)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFFECB3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.bestSeller,
                                      style: AppTypography.badge(
                                        color: const Color(0xFFE65100),
                                        isTamil: isTamil,
                                      ).copyWith(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Top Right: Discount Pill
                          if (hasDiscount && discountPercent > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.5,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),

                          // Out of Stock Overlay
                          if (!isAvailable || stock == 0)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF37474F),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.outOfStock,
                                  style: AppTypography.badge(
                                    color: Colors.white,
                                    isTamil: isTamil,
                                  ).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- MIDDLE ZONE: PRODUCT IDENTITY & METADATA ---
                    // Primary Name
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.productName(isTamil: isTamil).copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF162A1C),
                      ),
                    ),
                    const SizedBox(height: 1.5),

                    // Secondary Name / Local Variety
                    Text(
                      secondaryName.isNotEmpty ? secondaryName : product.origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.supporting(
                        color: const Color(0xFF5B7162),
                        isTamil: isTamil,
                      ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),

                    // Unit / Pack Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFE2E7E4),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        product.formatUnitLabel(isTamil: isTamil),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5F50),
                        ),
                      ),
                    ),

                    // --- CONTENT SPLIT DIVIDER ---
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 0.8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE8EDE9),
                            Color(0xFFF5F7F5),
                            Color(0xFFE8EDE9),
                          ],
                        ),
                      ),
                    ),

                    // --- BOTTOM ZONE: PRICING & QUICK-COMMERCE ACTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyFormatter.formatPaise(pricePaise),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF163E22),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    product.originalPricePaise!,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8A9A8F),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Color(0xFF8A9A8F),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Animated Quick-Commerce Button / Stepper
                        if (!isAvailable || stock == 0)
                          const SizedBox.shrink()
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: qtyInCart == 0
                                ? _buildAddButton(
                                    context,
                                    ref,
                                    currentBranch,
                                    cart,
                                    isTamil,
                                    l10n,
                                  )
                                : _buildQuantityStepper(
                                    context,
                                    ref,
                                    currentBranch,
                                    qtyInCart,
                                    isTamil,
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref,
    Branch currentBranch,
    Cart cart,
    bool isTamil,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      key: const ValueKey('add_btn'),
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
          elevation: 0,
        ),
        onPressed: () => _handleAddToCart(context, ref, currentBranch, cart),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.add,
              style: AppTypography.button(
                color: AppColors.primary,
                isTamil: isTamil,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.add, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(
    BuildContext context,
    WidgetRef ref,
    Branch currentBranch,
    int qtyInCart,
    bool isTamil,
  ) {
    final product = widget.product;
    return Container(
      key: const ValueKey('stepper_active'),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221B5E20),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ref
                  .read(cartProvider.notifier)
                  .decrementQuantity(product.id),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Icon(Icons.remove, size: 14, color: Colors.white),
              ),
            ),
          ),
          InkWell(
            onTap: () => QuantitySelectorSheet.show(
              context,
              product: product,
              initialQuantity: qtyInCart,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                product.formatQuantity(qtyInCart, isTamil: isTamil),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
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
                  VegoraToast.showWarning(
                    context,
                    isTamil
                        ? 'அதிகபட்ச இருப்பு அளவு எட்டப்பட்டது'
                        : 'Maximum available stock reached',
                    title: isTamil ? 'இருப்பு வரம்பு' : 'Stock Limit',
                  );
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    Branch currentBranch,
    Cart cart,
  ) async {
    final product = widget.product;
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
      VegoraToast.showSuccess(
        context,
        isTamil
            ? '${product.displayName("ta")} கூடையில் சேர்க்கப்பட்டது!'
            : '${product.name} added to cart!',
        title: isTamil ? 'கூடையில் சேர்க்கப்பட்டது' : 'Added to Cart',
        actionLabel: isTamil ? 'கூடை' : 'Cart',
        onAction: () => context.go('/cart'),
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
