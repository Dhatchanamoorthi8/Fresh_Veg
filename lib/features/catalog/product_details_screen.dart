import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/product.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/branch_switch_dialog.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/product_image_view.dart';
import '../../shared/widgets/quantity_selector_sheet.dart';
import '../../shared/widgets/vegora_toast.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int? _selectedQuantity;
  final TextEditingController _customQtyController = TextEditingController();
  bool _isCustomMode = false;

  @override
  void dispose() {
    _customQtyController.dispose();
    super.dispose();
  }

  int _getEffectiveQuantity(Product product) {
    if (_selectedQuantity != null) return _selectedQuantity!;
    return product.isWeightBased ? product.minOrderQuantity : 1;
  }

  void _onChipSelected(int gramsOrCount) {
    setState(() {
      _selectedQuantity = gramsOrCount;
      _isCustomMode = false;
      _customQtyController.clear();
    });
  }

  void _onCustomSubmitted(String input, Product product) {
    final parsedGrams = QuantitySelectorSheet.parseInputToGrams(
      input,
      isWeightBased: product.isWeightBased,
    );
    if (parsedGrams != null && parsedGrams > 0) {
      setState(() {
        _selectedQuantity = parsedGrams;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogRepo = ref.watch(catalogRepositoryProvider);
    final currentBranch = ref.watch(selectedBranchProvider);
    final cart = ref.watch(cartProvider);
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTamil ? 'காய்கறி விவரங்கள்' : 'Vegetable Details'),
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
        future: catalogRepo.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data!;
          final isAvailable = product.isAvailableAtBranch(currentBranch.id);
          final stock = product.getStockForBranch(currentBranch.id);
          final pricePaise = product.getPricePaiseForBranch(currentBranch.id);

          final selectedQty = _getEffectiveQuantity(product);
          final calculatedLinePrice = product.calculatePricePaise(
            selectedQty,
            pricePaise,
          );

          final primaryTitle = product.displayName(locale.languageCode);
          final secondaryTitle = isTamil
              ? product.name
              : product.displayName('ta');

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
                            _buildPill(
                              isTamil ? '100% இயற்கை' : '100% ORGANIC',
                              AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (product.isBestSeller) ...[
                            _buildPill(
                              isTamil ? 'அதிக விற்பனை' : 'BEST SELLER',
                              AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildPill(
                            isAvailable
                                ? (isTamil
                                      ? 'இருப்பு: ${product.formatQuantity(stock, isTamil: true)}'
                                      : 'IN STOCK: ${product.formatQuantity(stock)}')
                                : (isTamil
                                      ? 'கையிருப்பில் இல்லை'
                                      : 'OUT OF STOCK'),
                            isAvailable
                                ? AppColors.primaryDark
                                : AppColors.statusCancelled,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Name & Local Name with proper Tamil Line Height
                      Text(
                        primaryTitle,
                        style: AppTypography.screenHeading(isTamil: isTamil)
                            .copyWith(fontSize: 22),
                      ),
                      if (secondaryTitle.isNotEmpty &&
                          secondaryTitle != primaryTitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          secondaryTitle,
                          style: AppTypography.supporting(
                            color: AppColors.textSecondary,
                            isTamil: isTamil,
                          ).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Price and Unit
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatPaise(pricePaise),
                            style: AppTypography.productPrice(
                              color: AppColors.textPrimary,
                            ).copyWith(fontSize: 24),
                          ),
                          if (product.originalPricePaise != null &&
                              product.originalPricePaise! > pricePaise) ...[
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatPaise(
                                product.originalPricePaise!,
                              ),
                              style: AppTypography.originalPrice().copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            product.formatUnitLabel(isTamil: isTamil),
                            style:
                                AppTypography.supporting(
                                  color: AppColors.textSecondary,
                                  isTamil: isTamil,
                                ).copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Flexible Quantity Selector Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isTamil
                                      ? 'எடையைத் தேர்ந்தெடுக்கவும்'
                                      : 'Select Quantity',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${isTamil ? "விலை" : "Price"}: ${CurrencyFormatter.formatPaise(calculatedLinePrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Quantity Preset Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.isWeightBased
                                  ? [100, 250, 500, 750, 1000, 1500, 2000].map((
                                      grams,
                                    ) {
                                      final isSelected = selectedQty == grams;
                                      return ChoiceChip(
                                        selected: isSelected,
                                        label: Text(
                                          product.formatQuantity(
                                            grams,
                                            isTamil: isTamil,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        selectedColor: AppColors.primary,
                                        backgroundColor: Colors.white,
                                        onSelected: (val) {
                                          if (val) _onChipSelected(grams);
                                        },
                                      );
                                    }).toList()
                                  : [1, 2, 3, 5, 10].map((count) {
                                      final isSelected = selectedQty == count;
                                      return ChoiceChip(
                                        selected: isSelected,
                                        label: Text(
                                          product.formatQuantity(
                                            count,
                                            isTamil: isTamil,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        selectedColor: AppColors.primary,
                                        backgroundColor: Colors.white,
                                        onSelected: (val) {
                                          if (val) _onChipSelected(count);
                                        },
                                      );
                                    }).toList(),
                            ),

                            const SizedBox(height: 12),

                            // Stepper and Custom Quantity Bar
                            Row(
                              children: [
                                // Stepper
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          final step = product.isWeightBased
                                              ? product.quantityStep
                                              : 1;
                                          final next = selectedQty - step;
                                          final min = product.isWeightBased
                                              ? product.minOrderQuantity
                                              : 1;
                                          if (next >= min) {
                                            setState(() {
                                              _selectedQuantity = next;
                                            });
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          product.formatQuantity(
                                            selectedQty,
                                            isTamil: isTamil,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () {
                                          final step = product.isWeightBased
                                              ? product.quantityStep
                                              : 1;
                                          final next = selectedQty + step;
                                          if (next <= stock) {
                                            setState(() {
                                              _selectedQuantity = next;
                                            });
                                          } else {
                                            VegoraToast.showWarning(
                                              context,
                                              isTamil
                                                  ? 'அதிகபட்ச இருப்பு ${product.formatQuantity(stock, isTamil: true)} மட்டுமே'
                                                  : 'Maximum stock is ${product.formatQuantity(stock)}',
                                              title: isTamil
                                                  ? 'இருப்பு வரம்பு'
                                                  : 'Stock Limit',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Custom Input Toggle / Button
                                if (product.allowCustomQuantity &&
                                    product.isWeightBased) ...[
                                  Expanded(
                                    child: _isCustomMode
                                        ? SizedBox(
                                            height: 40,
                                            child: TextField(
                                              controller: _customQtyController,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                hintText: isTamil
                                                    ? 'எ.கா. 350g, 1.2kg'
                                                    : 'e.g. 350g, 1.2kg',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                                  onPressed: () =>
                                                      _onCustomSubmitted(
                                                        _customQtyController
                                                            .text
                                                            .trim(),
                                                        product,
                                                      ),
                                                ),
                                              ),
                                              onSubmitted: (val) =>
                                                  _onCustomSubmitted(
                                                    val.trim(),
                                                    product,
                                                  ),
                                            ),
                                          )
                                        : OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              side: const BorderSide(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.edit_note_rounded,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            label: Text(
                                              isTamil
                                                  ? 'தனிப்பயன் எடை'
                                                  : 'Custom Qty',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isCustomMode = true;
                                              });
                                            },
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

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
                                    isTamil
                                        ? '${currentBranch.name} கிளையிலிருந்து விநியோகம்'
                                        : 'Fulfilling from ${currentBranch.name}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? (isTamil
                                              ? '${product.formatQuantity(stock, isTamil: true)} கடையில் இருப்பு உள்ளது'
                                              : '${product.formatQuantity(stock)} available in-store')
                                        : (isTamil
                                              ? 'தற்போது இக்கிளையில் கிடைக்கவில்லை'
                                              : 'Currently unavailable at this branch'),
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
                      Text(
                        isTamil ? 'காய்கறி பற்றிய தகவல்' : 'About This Produce',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.displayDescription(locale.languageCode),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: isTamil ? 1.6 : 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Storage & Origin Specs
                      _buildSpecRow(
                        Icons.kitchen_rounded,
                        isTamil ? 'பாதுகாப்பு குறிப்புகள்' : 'Storage Tips',
                        product.storageTips,
                      ),
                      const SizedBox(height: 10),
                      _buildSpecRow(
                        Icons.agriculture_rounded,
                        isTamil ? 'பண்ணை மூலம்' : 'Farm Origin',
                        product.origin,
                      ),

                      const SizedBox(height: 28),

                      // Related Vegetables in same category
                      Text(
                        isTamil
                            ? 'நீங்கள் விரும்பக்கூடியவை'
                            : 'You May Also Like',
                        style: const TextStyle(
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
                            height: 240,
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

                      const SizedBox(height: 90),
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
        future: catalogRepo.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final product = snapshot.data!;
          final isAvailable = product.isAvailableAtBranch(currentBranch.id);
          final stock = product.getStockForBranch(currentBranch.id);
          final qtyInCart = ref
              .watch(cartProvider.notifier)
              .getQuantity(product.id);

          final selectedQty = _getEffectiveQuantity(product);
          final calculatedLinePrice = product.calculatePricePaise(
            selectedQty,
            product.getPricePaiseForBranch(currentBranch.id),
          );

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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.formatQuantity(selectedQty, isTamil: isTamil),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(calculatedLinePrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable && stock >= selectedQty
                              ? AppColors.primary
                              : AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: !isAvailable || stock < selectedQty
                            ? null
                            : () => _handleAddToCart(
                                context,
                                ref,
                                product,
                                currentBranch,
                                cart,
                                selectedQty,
                              ),
                        child: Text(
                          !isAvailable || stock == 0
                              ? (isTamil
                                    ? 'கையிருப்பில் இல்லை'
                                    : 'Out of Stock')
                              : stock < selectedQty
                              ? (isTamil
                                    ? 'போதுமான இருப்பு இல்லை'
                                    : 'Insufficient Stock')
                              : qtyInCart > 0
                              ? (isTamil
                                    ? 'கூடையில் சேர்க்கவும் (+)'
                                    : 'Add More to Cart')
                              : (isTamil ? 'கூடையில் சேர்' : 'Add to Cart'),
                          style: AppTypography.button(
                            color: Colors.white,
                            isTamil: isTamil,
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
      child: Text(label, style: AppTypography.badge(color: color)),
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
    int requestedQuantity,
  ) {
    final isTamil = ref.read(appLocaleProvider).languageCode == 'ta';

    try {
      ref
          .read(cartProvider.notifier)
          .addItem(product, currentBranch.id, quantity: requestedQuantity);
      VegoraToast.showSuccess(
        context,
        isTamil
            ? '${product.displayName("ta")} (${product.formatQuantity(requestedQuantity, isTamil: true)}) கூடையில் சேர்க்கப்பட்டது!'
            : '${product.name} (${product.formatQuantity(requestedQuantity)}) added to cart!',
        title: isTamil ? 'கூடையில் சேர்க்கப்பட்டது' : 'Added to Cart',
        actionLabel: isTamil ? 'கூடை' : 'View Cart',
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
                initialQuantity: requestedQuantity,
              );
          VegoraToast.showWarning(
            context,
            'Switched to ${currentBranch.name}. Cart refreshed.',
            title: 'Store Switched',
            icon: Icons.storefront_rounded,
          );
        },
      );
    }
  }
}
