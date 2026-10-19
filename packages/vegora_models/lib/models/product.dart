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
  final String nameTa;
  final String localName; // e.g. "Palak", "Tamatar", "Aloo"
  final String categoryId;
  final String unit; // "1 kg", "500 g", "1 bunch", "1 pc"
  final String unitType; // 'WEIGHT', 'COUNT', 'BUNCH'
  final String baseUnit; // 'g', 'pc', 'bunch'
  final int minOrderQuantity; // e.g. 100 for weight, 1 for pieces
  final int quantityStep; // e.g. 50 or 100 for weight, 1 for pieces
  final bool allowCustomQuantity;
  final String description;
  final String descriptionTa;
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
    this.nameTa = '',
    this.localName = '',
    this.categoryId = 'everyday_veggies',
    this.unit = '1 kg',
    this.unitType = 'WEIGHT',
    this.baseUnit = 'g',
    this.minOrderQuantity = 100,
    this.quantityStep = 50,
    this.allowCustomQuantity = true,
    this.description = '',
    this.descriptionTa = '',
    this.storageTips = '',
    this.origin = '',
    this.imageUrl,
    this.emoji = '🥗',
    this.isOrganic = false,
    this.isSeasonal = false,
    this.isBestSeller = false,
    this.isFeatured = false,
    this.isActive = true,
    required this.basePricePaise,
    this.originalPricePaise,
    this.branchInventory = const {},
  });

  bool get isWeightBased => unitType == 'WEIGHT';
  bool get isPieceBased => unitType == 'COUNT';
  bool get isBunchBased => unitType == 'BUNCH';

  /// Returns Tamil vegetable name when languageCode is 'ta' and available, else English name.
  String displayName([String? languageCode]) {
    if (languageCode == 'ta' && nameTa.trim().isNotEmpty) {
      return nameTa;
    }
    return name;
  }

  /// Returns Tamil description when languageCode is 'ta' and available, else English description.
  String displayDescription([String? languageCode]) {
    if (languageCode == 'ta' && descriptionTa.trim().isNotEmpty) {
      return descriptionTa;
    }
    return description;
  }

  /// Calculates authoritative line price in paise without floating-point errors.
  /// For weight products: (pricePerKg * quantityGrams) / 1000
  /// For count products: pricePerPiece * quantity
  int calculatePricePaise(int quantityGramsOrCount, int pricePaisePerKgOrPiece) {
    if (quantityGramsOrCount <= 0 || pricePaisePerKgOrPiece <= 0) return 0;
    if (isWeightBased) {
      return ((pricePaisePerKgOrPiece * quantityGramsOrCount) / 1000.0).round();
    }
    return pricePaisePerKgOrPiece * quantityGramsOrCount;
  }

  /// Formats quantity with appropriate units (e.g. 500 g -> "500 g" / "500 கிராம்")
  String formatQuantity(int quantityGramsOrCount, {bool isTamil = false}) {
    if (isWeightBased) {
      if (quantityGramsOrCount >= 1000 && quantityGramsOrCount % 100 == 0) {
        final kg = quantityGramsOrCount / 1000;
        final kgStr = kg % 1 == 0 ? kg.toInt().toString() : kg.toStringAsFixed(1);
        return isTamil ? '$kgStr கிலோ' : '$kgStr kg';
      }
      return isTamil ? '$quantityGramsOrCount கிராம்' : '$quantityGramsOrCount g';
    } else if (isBunchBased) {
      return isTamil
          ? '$quantityGramsOrCount கட்டு'
          : '$quantityGramsOrCount ${quantityGramsOrCount == 1 ? 'bunch' : 'bunches'}';
    } else {
      return isTamil
          ? '$quantityGramsOrCount எண்ணிக்கை'
          : '$quantityGramsOrCount ${quantityGramsOrCount == 1 ? 'pc' : 'pcs'}';
    }
  }

  /// Formats unit price label (e.g. "per kg" / "ஒரு கிலோ")
  String formatUnitLabel({bool isTamil = false}) {
    if (isWeightBased) {
      return isTamil ? 'ஒரு கிலோ' : 'per kg';
    } else if (isBunchBased) {
      return isTamil ? 'ஒரு கட்டு' : 'per bunch';
    } else {
      return isTamil ? 'ஒன்று' : 'per pc';
    }
  }

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

    final rawUnit = json['unit'] as String? ?? '1 kg';
    final inferredType = (rawUnit.contains('kg') || rawUnit.contains('g'))
        ? 'WEIGHT'
        : (rawUnit.contains('bunch') ? 'BUNCH' : 'COUNT');
    final resolvedUnitType = (json['unit_type'] as String?)?.toUpperCase() ?? inferredType;
    final resolvedBaseUnit = json['base_unit'] as String? ??
        (resolvedUnitType == 'WEIGHT' ? 'g' : (resolvedUnitType == 'BUNCH' ? 'bunch' : 'pc'));
    final defaultMin = resolvedUnitType == 'WEIGHT' ? 100 : 1;
    final defaultStep = resolvedUnitType == 'WEIGHT' ? 50 : 1;

    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? (json['id'] as String? ?? '').toUpperCase(),
      name: json['name'] as String,
      nameTa: json['name_ta'] as String? ?? '',
      localName: json['local_name'] as String? ?? '',
      categoryId: json['category_id'] as String,
      unit: rawUnit,
      unitType: resolvedUnitType,
      baseUnit: resolvedBaseUnit,
      minOrderQuantity: (json['min_order_quantity'] as num?)?.toInt() ?? defaultMin,
      quantityStep: (json['quantity_step'] as num?)?.toInt() ?? defaultStep,
      allowCustomQuantity: json['allow_custom_quantity'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? '',
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
      'name_ta': nameTa,
      'local_name': localName,
      'category_id': categoryId,
      'unit': unit,
      'unit_type': unitType,
      'base_unit': baseUnit,
      'min_order_quantity': minOrderQuantity,
      'quantity_step': quantityStep,
      'allow_custom_quantity': allowCustomQuantity,
      'description': description,
      'description_ta': descriptionTa,
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
    String? nameTa,
    String? localName,
    String? categoryId,
    String? unit,
    String? unitType,
    String? baseUnit,
    int? minOrderQuantity,
    int? quantityStep,
    bool? allowCustomQuantity,
    String? description,
    String? descriptionTa,
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
      nameTa: nameTa ?? this.nameTa,
      localName: localName ?? this.localName,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      unitType: unitType ?? this.unitType,
      baseUnit: baseUnit ?? this.baseUnit,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      quantityStep: quantityStep ?? this.quantityStep,
      allowCustomQuantity: allowCustomQuantity ?? this.allowCustomQuantity,
      description: description ?? this.description,
      descriptionTa: descriptionTa ?? this.descriptionTa,
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

  /// Get stock count for the given branch (0 if not configured).
  /// For weight products, returns stock in grams (e.g. 50,000 for 50kg).
  /// For count products, returns stock in pieces.
  int getStockForBranch(String branchId) {
    final override = branchInventory[branchId];
    if (override != null) {
      return override.stockQuantity;
    }
    return branchInventory.isEmpty ? (isWeightBased ? 50000 : 15) : 0;
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
