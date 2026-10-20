import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/category.dart';
import '../../shared/models/product.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBranch = ref.watch(selectedBranchProvider);
    final currentAddress = ref.watch(selectedAddressProvider);
    final catalogRepo = ref.watch(catalogRepositoryProvider);
    final cart = ref.watch(cartProvider);
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Premium Compact Header Bar
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border, width: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Brand Mark, Location Hub, and Header Actions
                        Row(
                          children: [
                            // Vegora Compact Brand Mark
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/branding/vegora_app_icon.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Delivery Location & Branch Selector
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/branches'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            size: 15,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              '${currentAddress.label} • ${currentAddress.area}',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: AppColors.textPrimary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Hub: ${currentBranch.name}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Cart Icon with Item Badge
                            InkWell(
                              onTap: () => context.go('/cart'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 19,
                                      color: AppColors.textPrimary,
                                    ),
                                    if (cart.isNotEmpty)
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 14,
                                            minHeight: 14,
                                          ),
                                          child: Text(
                                            '${cart.totalItemCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Profile Avatar Button
                            InkWell(
                              onTap: () => context.go('/profile'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 19,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Search Bar Button (navigates to catalog)
                        InkWell(
                          onTap: () => context.go('/catalog'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isTamil
                                        ? 'காய்கறிகள், கீரைகள், பழங்களை தேடுங்கள்...'
                                        : 'Search fresh vegetables, greens, fruits...',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Authentic Editorial Promotional Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Right-side photograph of real fresh vegetable basket
                        Positioned(
                          right: -10,
                          top: -10,
                          bottom: -10,
                          width: 150,
                          child: Opacity(
                            opacity: 0.95,
                            child: Image.asset(
                              'assets/branding/vegora_splash_basket.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Gradient overlay for flawless text contrast
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primaryDark.withValues(alpha: 0.96),
                                  AppColors.primaryDark.withValues(alpha: 0.65),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 0.72, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 130, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTamil
                                    ? 'தினசரி பண்ணை அறுவடை'
                                    : 'Daily Farm Harvest',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isTamil
                                    ? 'நேரடியாக உள்ளூர் பண்ணைகளில் இருந்து பறிக்கப்பட்ட புதிய காய்கறிகள்.'
                                    : 'Fresh greens & farm-fresh produce sourced direct from local growers.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isTamil
                                          ? '30 நிமிடங்களில் உங்கள் வீடு தேடி'
                                          : '30-Min Express Delivery',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTamil ? 'வகைகள்' : 'Shop by Category',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTamil
                                  ? 'பண்ணை காய்கறிகள் வகைவாரியாக'
                                  : 'Farm-fresh produce organized by type',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/catalog'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            isTamil ? 'அனைத்தும்' : 'See all',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Horizontal Tiles
                SliverToBoxAdapter(
                  child: FutureBuilder<List<ProductCategory>>(
                    future: catalogRepo.getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final categories = snapshot.data!;

                      return SizedBox(
                        height: 94,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final tint = _getCategoryTone(cat.id);

                            return InkWell(
                              onTap: () {
                                context.go('/catalog?categoryId=${cat.id}');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 84,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: tint.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tint.border,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cat.emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      cat.displayName(locale.languageCode),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Best Sellers Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTamil ? 'சிறந்த விற்பனை' : 'Best Sellers',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTamil ? 'இன்று அதிகம் விரும்பப்பட்ட பொருட்கள்' : 'Most ordered vegetables & essentials today',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/catalog'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            isTamil ? 'அனைத்தும்' : 'View all',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Best Sellers Horizontal Carousel
                SliverToBoxAdapter(
                  child: FutureBuilder<List<Product>>(
                    future: catalogRepo.getBestSellerProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!;

                      return SizedBox(
                        height: 242,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: products.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 164,
                              child: ProductCard(
                                product: products[index],
                                onTap: () => context.push(
                                  '/product/${products[index].id}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Seasonal Harvest Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTamil
                                  ? 'புதிய கீரைகள் & பருவக்கால அறுவடை'
                                  : 'Fresh Greens & Seasonal Harvest',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTamil
                                  ? 'தினமும் காலையில் சேகரிக்கப்படும் பசுமை'
                                  : 'Crisp greens picked fresh this morning',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/catalog'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            isTamil ? 'அனைத்தும்' : 'See all',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Seasonal Products Grid (2 columns on mobile, adaptive)
                FutureBuilder<List<Product>>(
                  future: catalogRepo.getSeasonalProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    final products = snapshot.data!;

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.67,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return ProductCard(
                            product: products[index],
                            onTap: () =>
                                context.push('/product/${products[index].id}'),
                          );
                        }, childCount: products.length),
                      ),
                    );
                  },
                ),

                // Bottom Padding for Floating Cart Summary
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Floating Sticky Cart Summary Bar (shows when cart has items)
            if (cart.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: InkWell(
                  onTap: () => context.go('/cart'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cart.totalItemCount} items • ${CurrencyFormatter.formatPaise(cart.subtotalPaise)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Fulfilling from ${currentBranch.area}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          isTamil ? 'கூடையைப் பார்' : 'View Cart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static _CategoryTone _getCategoryTone(String categoryId) {
    switch (categoryId) {
      case 'cat_leafy':
        return const _CategoryTone(
          background: Color(0xFFF2F8F4),
          border: Color(0xFFE0EFE5),
        );
      case 'cat_everyday':
        return const _CategoryTone(
          background: Color(0xFFFAF7F2),
          border: Color(0xFFEBE5DB),
        );
      case 'cat_roots':
        return const _CategoryTone(
          background: Color(0xFFFBF8EE),
          border: Color(0xFFEBE6D5),
        );
      case 'cat_onions_potatoes':
        return const _CategoryTone(
          background: Color(0xFFF6F8F6),
          border: Color(0xFFE4EAE4),
        );
      case 'cat_fruits':
        return const _CategoryTone(
          background: Color(0xFFFAF4F4),
          border: Color(0xFFEBE0E0),
        );
      case 'cat_seasonal_exotic':
        return const _CategoryTone(
          background: Color(0xFFF5F4FA),
          border: Color(0xFFE5E2F0),
        );
      default:
        return const _CategoryTone(
          background: Color(0xFFF6F8F6),
          border: Color(0xFFE4EAE4),
        );
    }
  }
}

class _CategoryTone {
  final Color background;
  final Color border;

  const _CategoryTone({required this.background, required this.border});
}
