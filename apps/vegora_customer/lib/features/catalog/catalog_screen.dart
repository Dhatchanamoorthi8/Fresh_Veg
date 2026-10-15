import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';
import 'package:vegora_ui/vegora_ui.dart';

enum SortOption { popularity, priceLowToHigh, priceHighToLow, nameAZ }

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategoryId;
  SortOption _currentSort = SortOption.popularity;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogRepo = ref.watch(catalogRepositoryProvider);
    final currentBranch = ref.watch(selectedBranchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vegetable & Fruit Mandi'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: RoleIndicatorBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search vegetables (e.g., Palak, Tomato)...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Products',
                  onPressed: () => _showSortBottomSheet(context),
                ),
              ],
            ),
          ),

          // Categories Horizontal Chips
          FutureBuilder<List<ProductCategory>>(
            future: catalogRepo.getCategories(),
            builder: (context, catSnapshot) {
              if (!catSnapshot.hasData) return const SizedBox.shrink();

              final categories = [
                const ProductCategory(
                  id: 'all',
                  name: 'All Items',
                  subtitle: 'सभी',
                  icon: Icons.grid_view_rounded,
                  emoji: '🧺',
                ),
                ...catSnapshot.data!,
              ];

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat.id == _selectedCategoryId;

                    return ChoiceChip(
                      selected: isSelected,
                      label: Text('${cat.emoji} ${cat.name}'),
                      onSelected: (val) {
                        setState(() => _selectedCategoryId = cat.id);
                      },
                    );
                  },
                ),
              );
            },
          ),

          // Filters summary row (In stock filter & Branch notice)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  'Store: ${currentBranch.area}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'In Stock Only',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _inStockOnly,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _inStockOnly = val),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Product Grid
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: catalogRepo.getProducts(
                categoryId: _selectedCategoryId,
                searchQuery: _searchController.text,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data!;

                // Filter in stock only if toggled
                if (_inStockOnly) {
                  products = products
                      .where((p) => p.isAvailableAtBranch(currentBranch.id))
                      .toList();
                }

                // Apply Sorting
                switch (_currentSort) {
                  case SortOption.popularity:
                    products.sort(
                      (a, b) =>
                          (b.isBestSeller ? 1 : 0) - (a.isBestSeller ? 1 : 0),
                    );
                    break;
                  case SortOption.priceLowToHigh:
                    products.sort(
                      (a, b) => a
                          .getPricePaiseForBranch(currentBranch.id)
                          .compareTo(
                            b.getPricePaiseForBranch(currentBranch.id),
                          ),
                    );
                    break;
                  case SortOption.priceHighToLow:
                    products.sort(
                      (a, b) => b
                          .getPricePaiseForBranch(currentBranch.id)
                          .compareTo(
                            a.getPricePaiseForBranch(currentBranch.id),
                          ),
                    );
                    break;
                  case SortOption.nameAZ:
                    products.sort((a, b) => a.name.compareTo(b.name));
                    break;
                }

                if (products.isEmpty) {
                  return EmptyStateView(
                    emoji: '🔍',
                    title: 'No Vegetables Found',
                    message: _searchController.text.isNotEmpty
                        ? 'No fresh produce matching "${_searchController.text}". Try searching for Palak, Tomato, or Onion.'
                        : 'No vegetables currently available in this category for ${currentBranch.name}.',
                    buttonText: 'Reset Search & Filters',
                    onButtonPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedCategoryId = 'all';
                        _inStockOnly = false;
                      });
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Sort Produce By',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              _buildSortTile(
                'Popularity / Best Sellers',
                SortOption.popularity,
              ),
              _buildSortTile('Price: Low to High', SortOption.priceLowToHigh),
              _buildSortTile('Price: High to Low', SortOption.priceHighToLow),
              _buildSortTile('Name: A to Z', SortOption.nameAZ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String title, SortOption option) {
    final isSelected = _currentSort == option;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _currentSort = option);
        Navigator.pop(context);
      },
    );
  }
}
