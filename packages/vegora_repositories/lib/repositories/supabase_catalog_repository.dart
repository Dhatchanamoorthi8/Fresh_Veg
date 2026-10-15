import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vegora_models/vegora_models.dart';
import 'catalog_repository.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  final SupabaseClient _client;

  SupabaseCatalogRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<ProductCategory>> getCategories() async {
    try {
      final res = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      return (res as List)
          .map((json) => ProductCategory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Admin method: Retrieve all categories including inactive ones
  Future<List<ProductCategory>> getAllCategories({
    bool includeInactive = true,
  }) async {
    try {
      var query = _client.from('categories').select();
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }
      final res = await query.order('sort_order');
      return (res as List)
          .map((json) => ProductCategory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all categories: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    String? branchId,
    bool inStockOnly = false,
  }) async {
    try {
      var query = _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        String mappedCat = categoryId;
        if (categoryId == 'cat_everyday') mappedCat = 'everyday_veggies';
        if (categoryId == 'cat_leafy') mappedCat = 'leafy_greens';
        if (categoryId == 'cat_roots') mappedCat = 'root_veggies';
        if (categoryId == 'cat_onions_potatoes') {
          mappedCat = 'onions_potatoes';
        }
        if (categoryId == 'cat_fruits') mappedCat = 'fresh_fruits';
        if (categoryId == 'cat_seasonal_exotic') {
          mappedCat = 'seasonal_harvest';
        }

        query = query.eq('category_id', mappedCat);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or('name.ilike.%$term%,local_name.ilike.%$term%');
      }

      final res = await query.order('name');
      var products = (res as List)
          .map((json) => Product.fromJson(json))
          .toList();

      if (branchId != null && inStockOnly) {
        products = products
            .where((p) => p.isAvailableAtBranch(branchId))
            .toList();
      }

      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  /// Admin method: Get all products with branch inventory
  Future<List<Product>> getAdminProducts({
    String? categoryId,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    try {
      var query = _client.from('products').select('''
        *,
        branch_inventory (*)
      ''');

      if (activeOnly != null) {
        query = query.eq('is_active', activeOnly);
      }

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or(
          'name.ilike.%$term%,local_name.ilike.%$term%,sku.ilike.%$term%',
        );
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching admin products: $e');
      rethrow;
    }
  }

  @override
  Future<Product?> getProductById(String id, {String? branchId}) async {
    try {
      final res = await _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return Product.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching product $id: $e');
      return null;
    }
  }

  @override
  Future<List<Product>> getFeaturedProducts({String? branchId}) async {
    try {
      final res = await _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('is_active', true)
          .limit(6);

      return (res as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getSeasonalProducts({String? branchId}) async {
    try {
      final res = await _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('is_active', true)
          .eq('is_seasonal', true)
          .limit(8);

      return (res as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching seasonal products: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getBestSellerProducts({String? branchId}) async {
    try {
      final res = await _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('is_active', true)
          .eq('is_bestseller', true)
          .limit(8);

      return (res as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching bestseller products: $e');
      return [];
    }
  }

  /// Urgent clearance and harvest deals
  Future<List<Product>> getUrgentClearanceProducts({String? branchId}) async {
    try {
      final res = await _client
          .from('products')
          .select('''
        *,
        branch_inventory (*)
      ''')
          .eq('is_active', true)
          .not('original_price_paise', 'is', null)
          .limit(6);

      return (res as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching clearance products: $e');
      return [];
    }
  }

  // --- Admin Methods ---

  /// Create a new vegetable product with branch-specific inventory configuration
  Future<Product> createVegetable({
    required Product product,
    required Map<String, BranchProductInventory> branchInventoryMap,
  }) async {
    try {
      // Validate unique SKU if provided
      if (product.sku.isNotEmpty) {
        final existing = await _client
            .from('products')
            .select('id')
            .eq('sku', product.sku)
            .maybeSingle();
        if (existing != null) {
          throw Exception(
            'A product with SKU "${product.sku}" already exists.',
          );
        }
      }

      final payload = product.toJson();
      payload['created_at'] = DateTime.now().toIso8601String();
      payload['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('products')
          .insert(payload)
          .select()
          .single();
      final newProduct = Product.fromJson(res);

      // Save branch-specific inventory records
      for (final entry in branchInventoryMap.entries) {
        final bId = entry.key;
        final inv = entry.value;

        await _client.from('branch_inventory').upsert({
          'branch_id': bId,
          'product_id': newProduct.id,
          'price_paise': inv.pricePaise ?? newProduct.basePricePaise,
          'stock_quantity': inv.stockQuantity,
          'low_stock_threshold': inv.lowStockThreshold,
          'is_available': inv.isAvailable,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return newProduct;
    } catch (e) {
      debugPrint('Error creating vegetable: $e');
      rethrow;
    }
  }

  /// Update vegetable details
  Future<Product> updateVegetable(Product product) async {
    try {
      final payload = product.toJson();
      payload['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('products')
          .update(payload)
          .eq('id', product.id)
          .select()
          .single();
      return Product.fromJson(res);
    } catch (e) {
      debugPrint('Error updating vegetable: $e');
      rethrow;
    }
  }

  /// Toggle product active status
  Future<void> toggleProductActive(String productId, bool isActive) async {
    try {
      await _client
          .from('products')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      debugPrint('Error toggling product status: $e');
      rethrow;
    }
  }

  /// Update or add branch inventory pricing, stock, and low stock threshold
  Future<void> updateBranchInventoryPricingAndStock({
    required String branchId,
    required String productId,
    required int pricePaise,
    required int stockQuantity,
    int lowStockThreshold = 5,
    required bool isAvailable,
  }) async {
    try {
      await _client.from('branch_inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'price_paise': pricePaise,
        'stock_quantity': stockQuantity,
        'low_stock_threshold': lowStockThreshold,
        'is_available': isAvailable,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating branch inventory pricing and stock: $e');
      rethrow;
    }
  }

  /// Legacy helper
  Future<void> updateBranchInventory({
    required String branchId,
    required String productId,
    int? pricePaise,
    required int stockQuantity,
    required bool isAvailable,
  }) async {
    await updateBranchInventoryPricingAndStock(
      branchId: branchId,
      productId: productId,
      pricePaise: pricePaise ?? 0,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
    );
  }

  /// Upload product image to Supabase Storage `product-images` bucket
  Future<String?> uploadProductImage(
    Uint8List bytes,
    String fileName, {
    String contentType = 'image/jpeg',
  }) async {
    try {
      final sanitizedName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\.-]'),
        '_',
      );
      final path =
          'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      await _client.storage
          .from('product-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      return _client.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading product image to Supabase Storage: $e');
      rethrow;
    }
  }

  // --- Category Management ---

  /// Create a new vegetable category
  Future<ProductCategory> createCategory(ProductCategory category) async {
    try {
      final existing = await _client
          .from('categories')
          .select('id')
          .eq('name', category.name)
          .maybeSingle();
      if (existing != null) {
        throw Exception('A category named "${category.name}" already exists.');
      }

      final payload = category.toJson();
      payload['created_at'] = DateTime.now().toIso8601String();
      final res = await _client
          .from('categories')
          .insert(payload)
          .select()
          .single();
      return ProductCategory.fromJson(res);
    } catch (e) {
      debugPrint('Error creating category: $e');
      rethrow;
    }
  }

  /// Update existing category
  Future<ProductCategory> updateCategory(ProductCategory category) async {
    try {
      final res = await _client
          .from('categories')
          .update(category.toJson())
          .eq('id', category.id)
          .select()
          .single();
      return ProductCategory.fromJson(res);
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  /// Toggle category active status
  Future<void> toggleCategoryActive(String categoryId, bool isActive) async {
    try {
      await _client
          .from('categories')
          .update({'is_active': isActive})
          .eq('id', categoryId);
    } catch (e) {
      debugPrint('Error toggling category status: $e');
      rethrow;
    }
  }

  // --- Promotion Management ---

  /// Get promotions list
  Future<List<Promotion>> getAllPromotions({
    bool includeInactive = true,
  }) async {
    try {
      var query = _client.from('promotions').select();
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }
      final res = await query.order('created_at', ascending: false);
      return (res as List).map((p) => Promotion.fromJson(p)).toList();
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      return [];
    }
  }

  /// Create a new promotion or urgent sale
  Future<Promotion> createPromotion(
    Promotion promotion, {
    List<String>? productIds,
  }) async {
    try {
      final payload = promotion.toJson();
      payload['created_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('promotions')
          .insert(payload)
          .select()
          .single();
      final created = Promotion.fromJson(res);

      if (productIds != null && productIds.isNotEmpty) {
        for (final pId in productIds) {
          await _client.from('promotion_products').insert({
            'promotion_id': created.id,
            'product_id': pId,
          });
        }
      }

      return created;
    } catch (e) {
      debugPrint('Error creating promotion: $e');
      rethrow;
    }
  }

  /// Toggle promotion active status
  Future<void> togglePromotionActive(String promoId, bool isActive) async {
    try {
      await _client
          .from('promotions')
          .update({'is_active': isActive})
          .eq('id', promoId);
    } catch (e) {
      debugPrint('Error toggling promotion status: $e');
      rethrow;
    }
  }
}
