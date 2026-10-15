class BranchProductInventory {
  final int? pricePaise;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool isAvailable;

  const BranchProductInventory({
    this.pricePaise,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    this.isAvailable = true,
  });

  factory BranchProductInventory.fromJson(Map<String, dynamic> json) {
    return BranchProductInventory(
      pricePaise: (json['price_paise'] as num?)?.toInt(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 5,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price_paise': pricePaise,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'is_available': isAvailable,
    };
  }
}

class Product {
  final String id;
  final String sku;
  final String name;
  final String localName; // e.g., "Palak", "Tamatar", "Aloo"
  final String categoryId;
  final String unit; // "500 g", "1 kg", "1 bunch", "250 g", "1 pc"
  final String description;
  final String storageTips;
  final String origin;
  final String? imageUrl;
  final String emoji;
  final bool isOrganic;
  final bool isSeasonal;
  final bool isBestSeller;
  final bool isFeatured;
  final bool isActive;
  final int basePricePaise;
  final int? originalPricePaise; // For showing discounts like ₹45 vs ₹55
  final Map<String, BranchProductInventory> branchInventory;

  const Product({
    required this.id,
    this.sku = '',
    required this.name,
    required this.localName,
    required this.categoryId,
    required this.unit,
    required this.description,
    required this.storageTips,
    required this.origin,
    this.imageUrl,
    required this.emoji,
    this.isOrganic = false,
    this.isSeasonal = false,
    this.isBestSeller = false,
    this.isFeatured = false,
    this.isActive = true,
    required this.basePricePaise,
    this.originalPricePaise,
    this.branchInventory = const {},
  });

  factory Product.fromJson(
    Map<String, dynamic> json, {
    Map<String, BranchProductInventory>? branchInventoryMap,
  }) {
    final inventory = <String, BranchProductInventory>{};
    if (branchInventoryMap != null) {
      inventory.addAll(branchInventoryMap);
    } else if (json['branch_inventory'] != null &&
        json['branch_inventory'] is List) {
      for (final inv in json['branch_inventory']) {
        final bId = inv['branch_id'] as String;
        inventory[bId] = BranchProductInventory.fromJson(inv);
      }
    }

    return Product(
      id: json['id'] as String,
      sku:
          json['sku'] as String? ?? (json['id'] as String? ?? '').toUpperCase(),
      name: json['name'] as String,
      localName: json['local_name'] as String? ?? '',
      categoryId: json['category_id'] as String,
      unit: json['unit'] as String,
      description: json['description'] as String? ?? '',
      storageTips: json['storage_tips'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      emoji: json['emoji'] as String? ?? '🥗',
      isOrganic: json['is_organic'] as bool? ?? false,
      isSeasonal: json['is_seasonal'] as bool? ?? false,
      isBestSeller: json['is_bestseller'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      basePricePaise: (json['base_price_paise'] as num?)?.toInt() ?? 0,
      originalPricePaise: (json['original_price_paise'] as num?)?.toInt(),
      branchInventory: inventory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (sku.isNotEmpty) 'sku': sku,
      'name': name,
      'local_name': localName,
      'category_id': categoryId,
      'unit': unit,
      'description': description,
      'storage_tips': storageTips,
      'origin': origin,
      'image_url': imageUrl,
      'emoji': emoji,
      'is_organic': isOrganic,
      'is_seasonal': isSeasonal,
      'is_bestseller': isBestSeller,
      'is_featured': isFeatured,
      'is_active': isActive,
      'base_price_paise': basePricePaise,
      'original_price_paise': originalPricePaise,
    };
  }

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? localName,
    String? categoryId,
    String? unit,
    String? description,
    String? storageTips,
    String? origin,
    String? imageUrl,
    String? emoji,
    bool? isOrganic,
    bool? isSeasonal,
    bool? isBestSeller,
    bool? isFeatured,
    bool? isActive,
    int? basePricePaise,
    int? originalPricePaise,
    Map<String, BranchProductInventory>? branchInventory,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      localName: localName ?? this.localName,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      storageTips: storageTips ?? this.storageTips,
      origin: origin ?? this.origin,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
      isOrganic: isOrganic ?? this.isOrganic,
      isSeasonal: isSeasonal ?? this.isSeasonal,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      basePricePaise: basePricePaise ?? this.basePricePaise,
      originalPricePaise: originalPricePaise ?? this.originalPricePaise,
      branchInventory: branchInventory ?? this.branchInventory,
    );
  }

  /// Get price for the given branch (or fallback to base price)
  int getPricePaiseForBranch(String branchId) {
    final override = branchInventory[branchId];
    if (override != null && override.pricePaise != null) {
      return override.pricePaise!;
    }
    return basePricePaise;
  }

  /// Get stock count for the given branch (0 if not configured)
  int getStockForBranch(String branchId) {
    final override = branchInventory[branchId];
    if (override != null) {
      return override.stockQuantity;
    }
    return branchInventory.isEmpty ? 15 : 0;
  }

  /// Check whether product is available in stock for the given branch
  bool isAvailableAtBranch(String branchId) {
    final override = branchInventory[branchId];
    if (override != null) {
      return override.isAvailable && override.stockQuantity > 0;
    }
    return branchInventory.isEmpty ? isActive : false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
